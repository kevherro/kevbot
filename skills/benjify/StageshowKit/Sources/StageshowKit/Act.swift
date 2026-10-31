import SwiftUI

/// A script: the story a ``Stage`` plays. It gets one ``Act`` per run and
/// stops when its `Task` is canceled (the stage left the screen, the app
/// went to the background, or the layout changed).
public typealias Script<S: Equatable> = @MainActor (Act<S>) async throws -> Void

/// What went wrong in a script, other than being canceled.
public enum StageError: Error, Equatable, Sendable {
  /// No view in the stage carries `.target(name)`.
  case noTarget(String)
}

/// A beat a script named with ``Act/mark(_:)``: when it happened and where
/// every target was at that moment.
public struct Mark: Sendable, Equatable, Codable {
  /// The name passed to `mark`.
  public var name: String
  /// Seconds since the run started, on the stage's clock.
  public var time: Double
  /// Every target's rect at that moment, in stage space.
  public var rects: [String: CGRect]
}

/// What a script is handed each run. It changes the scene state, drives the
/// touch cursor, and measures targets. Every `async` method throws
/// `CancellationError` once the run is canceled, and changes nothing after.
///
/// Waits and tweens run on the stage's injected clock, divided by its speed.
@MainActor
public final class Act<S: Equatable> {
  /// Which design is showing, so a script can aim or pace per layout.
  public let layout: StageLayout

  let model: StageModel<S>
  let store: RectStore
  let cursor: CursorModel
  let clock: ClockBox
  let speed: Double
  let finger: Bool
  let onMark: (Mark) -> Void

  init(layout: StageLayout, model: StageModel<S>, store: RectStore, cursor: CursorModel, clock: ClockBox, speed: Double, finger: Bool, onMark: @escaping (Mark) -> Void) {
    self.layout = layout
    self.model = model
    self.store = store
    self.cursor = cursor
    self.clock = clock
    self.speed = speed
    self.finger = finger
    self.onMark = onMark
  }

  // MARK: Scene

  /// Applies a change to scene state at once, without waiting for it to
  /// draw. For per-frame updates inside `drag` and `move`.
  public func put(_ patch: (inout S) -> Void) {
    guard !Task.isCancelled else { return }
    var next = model.state
    patch(&next)
    model.state = next
    model.gen += 1
  }

  /// Applies a change to scene state and returns once the stage has drawn
  /// it, so every `rect` read after it is fresh.
  public func set(_ patch: (inout S) -> Void) async throws {
    try Task.checkCancellation()
    put(patch)
    try await store.published(model.gen)
    try Task.checkCancellation()
  }

  /// Applies a change with animations off, for resets nothing on screen
  /// should explain. With `scope`, animations are off only inside the view
  /// marked `.target(scope)`.
  public func snap(_ patch: (inout S) -> Void, scope: String? = nil) async throws {
    try Task.checkCancellation()
    let key = scope ?? StageModel<S>.wholeStage
    model.instant.insert(key)
    defer { model.instant.remove(key) }
    var t = Transaction()
    if scope == nil { t.disablesAnimations = true }
    withTransaction(t) { put(patch) }
    try await store.published(model.gen)
    try await frame()
    try Task.checkCancellation()
  }

  /// Waits, on the stage's clock, divided by the stage's speed.
  public func wait(_ duration: Duration) async throws {
    try Task.checkCancellation()
    try await clock.sleep(duration / speed)
  }

  /// Names the current beat. The stage records it with every target's rect
  /// (see ``Mark``); a ``StageRecorder`` saves a still of it.
  public func mark(_ name: String) {
    guard !Task.isCancelled else { return }
    let m = Mark(name: name, time: clock.elapsed().seconds, rects: store.rects.byName)
    model.mark = name
    onMark(m)
  }

  /// Starts `body` for each item, `gap` apart, and waits for them all.
  public func stagger<T: Sendable>(_ items: [T], gap: Duration = .milliseconds(60), _ body: @escaping @MainActor (T, Int) async throws -> Void) async throws {
    // Child tasks, not a task group: they inherit the main actor, and the
    // run's cancellation reaches each of them.
    let tasks = items.enumerated().map { i, item in
      Task { @MainActor in
        if i > 0 { try await self.wait(gap * i) }
        try Task.checkCancellation()
        try await body(item, i)
      }
    }
    try await withTaskCancellationHandler {
      do {
        for t in tasks { try await t.value }
      } catch {
        for t in tasks { t.cancel() }
        throw error
      }
    } onCancel: {
      for t in tasks { t.cancel() }
    }
  }

  /// Types `text` into a string in state, one character at a time,
  /// `interval` apart on average, with the same uneven rhythm every run.
  public func type(_ key: WritableKeyPath<S, String>, _ text: String, interval: Duration = .milliseconds(35)) async throws {
    let chars = Array(text)
    for i in 0...chars.count {
      try Task.checkCancellation()
      put { $0[keyPath: key] = String(chars[0..<i]) }
      try await wait(interval * (0.7 + 0.6 * rhythm(i)))
    }
  }

  // MARK: Measuring

  /// Where a target is now, in stage space, or `nil` if no view carries it.
  public func rect(_ name: String) -> CGRect? { store.rects[name] }

  /// The point a target aims at, in stage space.
  public func center(_ target: Target) throws -> CGPoint { try resolve(target) }

  /// The character offset a text selection reaches with the pointer at
  /// `at`, as the system works it out: above the text is its start, below is
  /// its end, beside a line clamps to that line, between lines takes the
  /// nearer. The text needs `.caretTarget(name)`.
  public func caret(_ name: String, at point: CGPoint) -> Int {
    caretOffset(store.chars[name] ?? [], at: point)
  }

  // MARK: Pointer

  /// Moves the touch point in a shallow, hand-like arc, timed by distance.
  /// A touch cursor shows nothing between touches. `path` replaces the arc:
  /// it gets eased progress (0...1) and the endpoints. `onMove` gets each
  /// point on the way.
  public func move(to target: Target, duration: Duration? = nil, path: (@MainActor (Double, CGPoint, CGPoint) -> CGPoint)? = nil, onMove: (@MainActor (CGPoint, CGPoint, Double) -> Void)? = nil) async throws {
    try Task.checkCancellation()
    let from = cursor.position
    let end = try resolve(target)
    let dist = hypot(end.x - from.x, end.y - from.y)
    if dist < 0.5 { return }
    let ms = duration?.milliseconds ?? clamp(260 + dist * 0.9, 300, 650)
    let bow = min(dist * 0.08, 24)
    let nx = -(end.y - from.y) / dist, ny = (end.x - from.x) / dist
    try await tween(ms) { t in
      let e = easeInOutCubic(t)
      let lift = sin(.pi * e) * bow
      let p = path?(e, from, end) ?? CGPoint(x: from.x + (end.x - from.x) * e + nx * lift, y: from.y + (end.y - from.y) * e + ny * lift)
      self.cursor.position = p
      onMove?(p, from, t)
    }
  }

  /// Moves to the target (if given) and taps it. A touch cursor shows its
  /// dot just before the press and lets it go after the lift. While pressed
  /// the target's name is in `@Environment(\.stagePressed)`.
  public func click(_ target: Target? = nil, double: Bool = false) async throws {
    try Task.checkCancellation()
    if let target {
      try await move(to: target)
      try await wait(.milliseconds(120))
    }
    let name = target.flatMap { name(of: $0) }
    defer {
      cursor.pressed = false
      if let name { model.pressed.remove(name) }
      if finger { lift() }
    }
    if finger {
      cursor.touching = true
      try await wait(.milliseconds(140))
    }
    for i in 0..<(double ? 2 : 1) {
      if i > 0 { try await wait(.milliseconds(70)) }
      cursor.pressed = true
      if let name { model.pressed.insert(name) }
      try await wait(.milliseconds(double ? 80 : 100))
      cursor.pressed = false
      if let name { model.pressed.remove(name) }
    }
  }

  /// Presses, carries to the target and lifts. A finger lands already
  /// moving, gathers speed over the first quarter, and is still moving as it
  /// lifts. `onMove` gets each point, in the same frame as the cursor.
  public func drag(to target: Target, duration: Duration? = nil, path: (@MainActor (Double, CGPoint, CGPoint) -> CGPoint)? = nil, onMove: (@MainActor (CGPoint, CGPoint, Double) -> Void)? = nil) async throws {
    try Task.checkCancellation()
    let from = cursor.position
    let end = try resolve(target)
    let dist = hypot(end.x - from.x, end.y - from.y)
    defer {
      cursor.pressed = false
      cursor.swiping = false
      if finger { lift() }
    }
    if finger {
      cursor.touching = true
      try await wait(.milliseconds(140))
    }
    cursor.pressed = true
    try await wait(.milliseconds(finger ? 170 : 60))
    if finger { cursor.swiping = true } else { try await wait(.milliseconds(70)) }
    cursor.pressed = false
    let bow = min(dist * 0.06, 18)
    let nx = dist > 0 ? -(end.y - from.y) / dist : 0, ny = dist > 0 ? (end.x - from.x) / dist : 0
    let ms = duration?.milliseconds ?? (finger ? clamp(180 + dist * 0.5, 240, 300) : clamp(360 + dist * 1.1, 450, 900))
    try await tween(ms) { t in
      let e = self.finger ? fingerEase(t) : easeInOutCubic(t)
      let lift = sin(.pi * min(e, 1)) * bow
      let at = path?(e, from, end) ?? CGPoint(x: from.x + (end.x - from.x) * e + nx * lift, y: from.y + (end.y - from.y) * e + ny * lift)
      onMove?(at, from, t)
      self.cursor.position = at
    }
  }

  /// Puts the touch point there at once, with no travel. Only behind a cut.
  public func place(_ target: Target) throws {
    guard !Task.isCancelled else { return }
    cursor.position = try resolve(target)
  }

  /// Brings the touch point in from past the stage edge nearest the target,
  /// already moving, and settles it there.
  public func enter(_ target: Target, duration: Duration = .milliseconds(700)) async throws {
    try Task.checkCancellation()
    let end = try resolve(target)
    let size = model.designSize
    let out: CGFloat = 40
    let gaps = [end.x, size.width - end.x, end.y, size.height - end.y]
    let side = gaps.firstIndex(of: gaps.min()!)!
    let from: CGPoint = switch side {
    case 0: CGPoint(x: -out, y: end.y + size.height * 0.12)
    case 1: CGPoint(x: size.width + out * 0.4, y: end.y + size.height * 0.12)
    case 2: CGPoint(x: end.x - size.width * 0.06, y: -out)
    default: CGPoint(x: end.x + size.width * 0.06, y: size.height + out * 0.4)
    }
    cursor.position = from
    try await tween(duration.milliseconds) { t in
      let e = Ease.enter(t)
      self.cursor.position = CGPoint(x: from.x + (end.x - from.x) * e, y: from.y + (end.y - from.y) * e)
    }
  }

  // MARK: Internals

  private func lift() {
    let token = cursor.touch &+ 1
    cursor.touch = token
    let clock = self.clock, speed = self.speed, cursor = self.cursor
    Task { @MainActor in
      try? await clock.sleep(.milliseconds(240) / speed)
      if cursor.touch == token { cursor.touching = false }
    }
  }

  func frame() async throws { try await clock.sleep(.frame) }

  private func tween(_ ms: Double, _ step: @MainActor (Double) -> Void) async throws {
    let dur = ms / speed / 1000
    let start = clock.elapsed().seconds
    while true {
      try Task.checkCancellation()
      let t = dur <= 0 ? 1 : min(1, (clock.elapsed().seconds - start) / dur)
      step(t)
      if t >= 1 { return }
      try await frame()
    }
  }

  private func name(of target: Target) -> String? {
    switch target {
    case let .name(n), let .at(n, _, _): n
    case .point: nil
    case let .perLayout(wide, compact): name(of: layout == .compact ? compact : wide)
    }
  }

  func resolve(_ target: Target) throws -> CGPoint {
    switch target {
    case let .point(p): return p
    case let .perLayout(wide, compact): return try resolve(layout == .compact ? compact : wide)
    case let .name(n): return try resolve(.at(n, x: 0.5, y: 0.5))
    case let .at(n, x, y):
      guard let r = store.rects[n] else { throw StageError.noTarget(n) }
      return CGPoint(x: r.minX + r.width * x, y: r.minY + r.height * y)
    }
  }
}

// A finger gathers speed over the first quarter, then holds one speed to
// the lift, still moving when it leaves.
func fingerEase(_ t: Double) -> Double {
  let a = 0.25, k = 1 / (1 - a / 2)
  return t < a ? (t * t) / (2 * a) * k : (t - a / 2) * k
}

func caretOffset(_ chars: [CaretChar], at p: CGPoint) -> Int {
  guard let first = chars.first, let last = chars.last else { return 0 }
  let end = last.offset + 1
  if p.y < first.rect.minY { return 0 }
  if p.y > last.rect.maxY { return end }
  // The visual line nearest the pointer, then the boundary nearest it on it.
  var line = first.rect
  for c in chars where abs(c.rect.midY - p.y) < abs(line.midY - p.y) { line = c.rect }
  let row = chars.filter { abs($0.rect.minY - line.minY) < line.height / 2 }
  if let next = row.first(where: { $0.rect.midX > p.x }) { return next.offset }
  return (row.last?.offset ?? end - 1) + 1
}
extension Duration {
  static let frame = Duration.nanoseconds(8_333_333)
  var seconds: Double { Double(components.seconds) + Double(components.attoseconds) / 1e18 }
  var milliseconds: Double { seconds * 1000 }
}

/// An `any Clock<Duration>` opened once, so the act can read elapsed time
/// without knowing the clock's instant type.
struct ClockBox: Sendable {
  let elapsed: @Sendable () -> Duration
  let sleep: @Sendable (Duration) async throws -> Void

  init(_ clock: any Clock<Duration>) {
    func open<C: Clock<Duration>>(_ c: C) -> ClockBox { ClockBox(c, start: c.now) }
    self = open(clock)
  }

  private init<C: Clock<Duration>>(_ c: C, start: C.Instant) {
    elapsed = { start.duration(to: c.now) }
    sleep = { d in try await c.sleep(for: d, tolerance: .zero) }
  }
}
