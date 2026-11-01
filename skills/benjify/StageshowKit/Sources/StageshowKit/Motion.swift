import SwiftUI

// Motion parts that have to hold up frame by frame. Upstream: motion/Count,
// Roll, Swap, Connector, States.

// MARK: Count

/// A number whose changed digits roll from the old figure to the new one,
/// the last digit first, the way a counter does. A rise rolls the figures
/// up, a fall rolls them down, and a digit passing 9 carries on into 0
/// rather than spinning back. Unchanged digits and punctuation hold still;
/// figures are tabular. A unit the format writes after the figure ("21°",
/// "12 min") sits in a box of its own. Inside a `snap`, offscreen or under
/// Reduce Motion it jumps to the value.
///
/// It reserves no width for extra digits: give it a stable slot when its
/// neighbors must stay still.
public struct Count: View {
  let value: Double
  let format: (Double) -> String
  let duration: Double, stagger: Double

  @State private var shown: (text: String, value: Double)?
  @State private var idx: [Int] = []
  @State private var cell: CGFloat = 0
  @State private var settleTask: Task<Void, Never>?
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  /// Creates a count. `duration` is how long one digit rolls; `stagger`
  /// the gap between one digit starting and the next, from the right.
  public init(_ value: Double, duration: Duration = .milliseconds(700), stagger: Duration = .milliseconds(45), format: @escaping (Double) -> String = { String(Int($0.rounded())) }) {
    self.value = value; self.format = format
    self.duration = duration.seconds; self.stagger = stagger.seconds
  }

  static let middle = 10

  /// Where each digit column's strip moves for a change from `before` to
  /// `after` (digits read from the right), starting from `at`. The shortest
  /// turn in the value's direction, so 9 to 1 rising passes through 0.
  static func roll(from before: [Int], to after: [Int], at: [Int], up: Bool, instant: Bool) -> [Int] {
    after.enumerated().map { c, d in
      guard !instant, c < before.count, c < at.count else { return middle + d }
      let was = before[c]
      if was == d { return at[c] }
      return up ? at[c] + (d - was + 10) % 10 : at[c] - (was - d + 10) % 10
    }
  }

  static func digitsFromRight(_ s: String) -> [Int] { s.reversed().compactMap { $0.wholeNumberValue } }

  static func unit(_ text: String) -> (head: String, space: Bool, unit: String) {
    guard let last = text.lastIndex(where: \.isNumber) else { return (text, false, "") }
    let tail = text[text.index(after: last)...]
    let trimmed = tail.drop { $0 == " " }
    guard !trimmed.isEmpty, !trimmed.contains(where: { $0.isNumber || $0 == "." || $0 == "," }) else { return (text, false, "") }
    return (String(text[...last]), trimmed.count < tail.count, String(trimmed))
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let text = format(value)
    let (head, space, unit) = Self.unit(text)
    let digits = Self.digitsFromRight(text)
    let at = idx.count == digits.count ? idx : digits.map { Self.middle + $0 }
    let quiet = still || instant
    // Columns are numbered from the right, so a total that gains a digit
    // keeps its existing digits rolling in place.
    let cols: [(ch: Character, col: Int?)] = {
      var n = digits.count
      return head.map { ch in ch.isNumber ? { n -= 1; return (ch, n) }() : (ch, nil) }
    }()
    HStack(alignment: .firstTextBaseline, spacing: 0) {
      ForEach(Array(cols.enumerated()), id: \.offset) { _, item in
        if let c = item.col, let d = item.ch.wholeNumberValue {
          Text("0").hidden().overlay(alignment: .top) {
            VStack(spacing: 0) {
              ForEach(0..<30, id: \.self) { k in Text(String(k % 10)).frame(height: cell) }
            }
            .offset(y: -CGFloat(c < at.count ? at[c] : Self.middle + d) * cell)
            .animation(quiet ? nil : .timingCurve(0.3, 0.75, 0.1, 1, duration: duration).delay(Double(c) * stagger), value: c < at.count ? at[c] : 0)
          }
          .clipped()
          .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.08), .init(color: .black, location: 0.92), .init(color: .clear, location: 1)], startPoint: .top, endPoint: .bottom))
          .id("d\(c)")
        } else {
          Text(String(item.ch))
        }
      }
      if !unit.isEmpty { Text(unit).padding(.leading, space ? 0.28 * cell : 0.08 * cell) }
    }
    .monospacedDigit()
    .background(Text("0").hidden().onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cell = $0 })
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(text)
    .onChange(of: text, initial: true) { _, new in
      let digits = Self.digitsFromRight(new)
      guard let prev = shown else {
        shown = (new, value)
        idx = digits.map { Self.middle + $0 }
        return
      }
      let next = Self.roll(from: Self.digitsFromRight(prev.text), to: digits, at: idx, up: value >= prev.value, instant: quiet)
      shown = (new, value)
      idx = next
      // Once every digit has landed, put the strips back in the middle
      // decade with no animation, ready for the next change.
      settleTask?.cancel()
      let wait = duration + stagger * Double(digits.count) + 0.06
      settleTask = Task { @MainActor in
        try? await Task.sleep(for: .seconds(wait))
        guard !Task.isCancelled else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) { idx = digits.map { Self.middle + $0 } }
      }
    }
  }
}

// MARK: Roll

/// Text that rolls when it changes, only the part that differs: in "$0.01
/// per 1,000" to "$0.0098 per 1,000" the shared ends hold still. Digits
/// change one by one; words move whole. The changing part eases to its new
/// width and what follows moves with it. `.fade` crossfades in place with a
/// small lift, for labels on controls. `delay` holds the old text first.
public struct Roll: View {
  /// How a `Roll` changes its text.
  public enum Variant: Sendable {
    /// Slides up through the line: numbers and inline text.
    case roll
    /// Crossfades in place with a small lift: a control's label.
    case fade
  }

  let text: String, variant: Variant, delay: Double, stagger: Double, trailing: Bool
  @State private var view = Parts(text: "", head: 0, tail: 0, old: "", key: 0, numeric: true)
  @State private var started = false
  @State private var width: CGFloat?
  @State private var target: CGFloat = 0
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  struct Parts: Equatable { var text: String; var head: Int; var tail: Int; var old: String; var key: Int; var numeric: Bool }

  /// Creates rolling text. `alignment: .trailing` pins it to its right
  /// edge, for a right-aligned value.
  public init(_ text: String, variant: Variant = .roll, delay: Duration = .zero, stagger: Duration = .milliseconds(45), alignment: HorizontalAlignment = .leading) {
    self.text = text; self.variant = variant; self.delay = delay.seconds; self.stagger = stagger.seconds
    self.trailing = alignment == .trailing
  }

  /// The shared head and tail of two strings, snapped out to whole words
  /// unless the change is numeric.
  static func split(_ a: String, _ b: String) -> (head: Int, tail: Int, numeric: Bool) {
    let a = Array(a), b = Array(b)
    var head = 0
    while head < a.count, head < b.count, a[head] == b[head] { head += 1 }
    var tail = 0
    while tail < a.count - head, tail < b.count - head, a[a.count - 1 - tail] == b[b.count - 1 - tail] { tail += 1 }
    let changed = String(a[head..<(a.count - tail)]) + String(b[head..<(b.count - tail)])
    let numeric = changed.allSatisfy { "0123456789.,$€£%+-− ".contains($0) }
    if !numeric {
      func space(_ i: Int) -> Bool { i < 0 || i >= b.count || b[i].isWhitespace }
      while head > 0, !space(head - 1), !space(head) { head -= 1 }
      while tail > 0, !space(b.count - tail - 1), !space(b.count - tail) { tail -= 1 }
    }
    return (head, tail, numeric)
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let quiet = still || instant
    let v = quiet || !started ? Parts(text: text, head: 0, tail: 0, old: "", key: 0, numeric: true) : view
    let chars = Array(v.text)
    let head = String(chars[0..<v.head]), now = String(chars[v.head..<(chars.count - v.tail)]), tail = String(chars[(chars.count - v.tail)...])
    HStack(spacing: 0) {
      Text(head)
      ZStack(alignment: trailing ? .trailing : .leading) {
        if !v.old.isEmpty { RollOut(text: v.old, variant: variant).id("o\(v.key)") }
        Group {
          if v.key == 0 {
            Text(now)
          } else if variant == .fade {
            RollIn(text: now, delay: 0.12, variant: .fade)
          } else {
            let units = v.numeric ? now.map(String.init) : now.split(separator: " ", omittingEmptySubsequences: false).enumerated().map { i, w in i == 0 ? String(w) : " " + w }
            HStack(spacing: 0) {
              ForEach(Array(units.enumerated()), id: \.offset) { i, u in RollIn(text: u, delay: 0.11 + Double(i) * stagger, variant: .roll) }
            }
          }
        }
        .id("n\(v.key)")
        .background(Text(now).fixedSize().hidden().onGeometryChange(for: CGFloat.self) { $0.size.width } action: { target = $0 })
      }
      .frame(width: width, alignment: trailing ? .trailing : .leading)
      .mask(Rectangle().padding(.horizontal, variant == .fade ? 0 : -400))
      Text(tail)
    }
    .fixedSize()
    .onChange(of: target) { old, new in
      guard v.key > 0, !quiet else { width = nil; return }
      if variant == .fade {
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.4)) { width = new }
      } else {
        // Open to the wider of the two so neither runs into what follows,
        // then settle to the new width.
        let widest = max(old, new)
        withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5)) { width = widest }
        if widest != new {
          Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: 0.5)) { width = new }
          }
        }
      }
    }
    .onChange(of: text, initial: true) { _, new in
      guard started else { started = true; view = Parts(text: new, head: 0, tail: 0, old: "", key: 0, numeric: true); return }
      let from = view.text
      guard from != new else { return }
      let apply = {
        let (h, t, numeric) = Self.split(from, new)
        let a = Array(from)
        let old = String(a[h..<(a.count - t)])
        width = width ?? target
        view = Parts(text: new, head: h, tail: t, old: old, key: view.key + 1, numeric: numeric)
        let key = view.key
        Task { @MainActor in
          try? await Task.sleep(for: .milliseconds(700))
          if view.key == key { view.old = "" }
        }
      }
      if delay > 0, !quiet {
        Task { @MainActor in
          try? await Task.sleep(for: .seconds(delay))
          if text == new { apply() }
        }
      } else {
        apply()
      }
    }
  }

  struct RollIn: View {
    let text: String, delay: Double, variant: Variant
    @State private var shown = false
    var body: some View {
      Text(text)
        .offset(y: shown ? 0 : (variant == .fade ? 0 : 14))
        .opacity(shown ? 1 : 0)
        .blur(radius: shown ? 0 : 1)
        .onAppear {
          withAnimation(.timingCurve(0.22, 1, 0.36, 1, duration: variant == .fade ? 0.35 : 0.55).delay(delay)) { shown = true }
        }
    }
  }

  struct RollOut: View {
    let text: String, variant: Variant
    @State private var gone = false
    var body: some View {
      Text(text)
        .fixedSize()
        .offset(y: gone ? (variant == .fade ? -3 : -14) : 0)
        .opacity(gone ? 0 : 1)
        .blur(radius: gone ? 1 : 0)
        .onAppear {
          withAnimation(.timingCurve(0.55, 0, 1, 0.45, duration: variant == .fade ? 0.16 : 0.28)) { gone = true }
        }
    }
  }
}

// MARK: Swap

/// Text (or anything) replaced in place, keyed on what changed: the old
/// fades out, the new fades in, and the box eases between their sizes so
/// what is around it moves with it, never snaps. Narrowing, the box waits
/// while the old words fade so they are never cut mid-word.
public struct Swap<ID: Hashable, Content: View>: View {
  let id: ID, duration: Double
  let content: Content
  @State private var size: CGSize?
  @State private var shrinking = false
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  /// Creates a swap keyed on `id`.
  public init(id: ID, duration: Duration = .milliseconds(450), @ViewBuilder content: () -> Content) {
    self.id = id; self.duration = duration.seconds; self.content = content()
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let quiet = still || instant
    ZStack(alignment: .leading) {
      content
        .fixedSize()
        .onGeometryChange(for: CGSize.self) { $0.size } action: { new in
          guard let old = size, !quiet else { size = new; return }
          shrinking = new.width < old.width
          withAnimation(.timingCurve(0.25, 0.8, 0.25, 1, duration: duration).delay(shrinking ? duration * 0.5 : 0)) { size = new }
        }
        .id(id)
        .transition(quiet ? .identity : .asymmetric(
          insertion: .modifier(active: SwapFade(on: false), identity: SwapFade(on: true)).animation(.timingCurve(0.25, 0.8, 0.25, 1, duration: duration * 0.7).delay(duration * 0.3)),
          removal: .modifier(active: SwapFade(on: false), identity: SwapFade(on: true)).animation(.easeInOut(duration: duration * 0.5))))
    }
    .frame(width: size?.width, height: size?.height, alignment: .leading)
    // Clips sideways only: a word cannot spill while the box narrows.
    .mask(Rectangle().padding(.vertical, -40))
  }
}

// Outside Swap: inside it, `Content` would name Swap's generic parameter.
private struct SwapFade: ViewModifier {
  let on: Bool
  func body(content: Content) -> some View { content.opacity(on ? 1 : 0).blur(radius: on ? 0 : 1) }
}

// MARK: Connector

/// A line that ties one thing to another and ends on a dot: a row to its
/// detail card, a value to its note. Points are in stage space (from the
/// overlay's `rects`); put it in the stage's overlay. It draws on when
/// `show` turns true and fades off intact when it turns false; the end dot
/// and label arrive after the line.
public struct Connector: View {
  /// The path between the ends.
  public enum Route: Sendable {
    /// Across, then down or up.
    case h
    /// Down or up, then across.
    case v
    /// A direct line.
    case straight
    /// Across, down or up halfway, then across again, entering level.
    case step
    /// The step's path as one soft S.
    case curve
  }
  /// Which ends get a dot.
  public enum Dots: Sendable {
    /// The end only.
    case end
    /// Both ends.
    case both
    /// Neither.
    case none
  }

  let from: CGPoint, to: CGPoint, route: Route, show: Bool, radius: CGFloat
  let dots: Dots?, arrow: Bool, label: String?, labelAt: CGFloat, dashed: Bool
  @Environment(\.stageLook) private var look
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  /// Creates a connector.
  public init(from: CGPoint, to: CGPoint, route: Route = .h, show: Bool, radius: CGFloat = 8, dots: Dots? = nil, arrow: Bool = false, label: String? = nil, labelAt: CGFloat = 0.5, dashed: Bool = false) {
    self.from = from; self.to = to; self.route = route; self.show = show; self.radius = radius
    self.dots = dots; self.arrow = arrow; self.label = label; self.labelAt = labelAt; self.dashed = dashed
  }

  static let draw = 1.0

  /// The part, drawn from its inputs.
  public var body: some View {
    let quiet = still || instant
    let ends = dots ?? (arrow ? .none : .end)
    let pts = Self.corners(from, to, route)
    let line = Self.elbow(from, to, route, radius)
    ZStack(alignment: .topLeading) {
      line
        .trim(from: 0, to: show ? 1 : 0)
        .stroke(look.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .butt, dash: dashed ? [4, 4] : []))
        .animation(quiet ? nil : show ? .timingCurve(0.65, 0, 0.35, 1, duration: Self.draw) : .linear(duration: 0.01).delay(0.25), value: show)
        .opacity(show ? 1 : 0)
        .animation(quiet ? nil : .easeInOut(duration: show ? 0.01 : 0.25), value: show)
      if arrow, let q = pts.last, let p = pts.dropLast().last(where: { hypot(q.x - $0.x, q.y - $0.y) > 0.001 }) {
        Self.head(p, q)
          .stroke(look.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
          .opacity(show ? 1 : 0)
          .animation(quiet ? nil : .easeInOut(duration: 0.2).delay(show ? Self.draw : 0), value: show)
      }
      if ends == .both { dot(at: from, delay: 0) }
      if ends != .none { dot(at: to, delay: Self.draw) }
      if let label {
        let at = Self.along(pts, labelAt)
        Text(label)
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(look.text)
          .padding(.horizontal, 6).padding(.vertical, 2)
          .background(Capsule().fill(look.surface).shadow(color: .black.opacity(0.1), radius: 1, y: 1))
          .position(at)
          .opacity(show ? 1 : 0)
          .animation(quiet ? nil : .easeInOut(duration: 0.25).delay(show ? Self.draw : 0), value: show)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .allowsHitTesting(false)
    .accessibilityHidden(true)
  }

  private func dot(at p: CGPoint, delay: Double) -> some View {
    let quiet = still || instant
    return Circle()
      .fill(look.accent)
      .overlay(Circle().stroke(.white, lineWidth: 2))
      .frame(width: 6, height: 6)
      .shadow(color: Color(red: 20 / 255, green: 35 / 255, blue: 55 / 255).opacity(0.16), radius: 0.5, y: 1)
      .scaleEffect(show ? 1 : 0.4)
      .opacity(show ? 1 : 0)
      .animation(quiet ? nil : .timingCurve(0.22, 1, 0.36, 1, duration: 0.3).delay(show ? delay : 0), value: show)
      .position(p)
  }

  static func corners(_ a: CGPoint, _ b: CGPoint, _ route: Route) -> [CGPoint] {
    switch route {
    case .straight: return [a, b]
    case .curve:
      let m = (a.x + b.x) / 2
      let c1 = CGPoint(x: m, y: a.y), c2 = CGPoint(x: m, y: b.y)
      return (0...24).map { i in
        let t = CGFloat(i) / 24, u = 1 - t
        return CGPoint(x: u * u * u * a.x + 3 * u * u * t * c1.x + 3 * u * t * t * c2.x + t * t * t * b.x,
                       y: u * u * u * a.y + 3 * u * u * t * c1.y + 3 * u * t * t * c2.y + t * t * t * b.y)
      }
    case .step:
      let m = (a.x + b.x) / 2
      return [a, CGPoint(x: m, y: a.y), CGPoint(x: m, y: b.y), b]
    case .h: return [a, CGPoint(x: b.x, y: a.y), b]
    case .v: return [a, CGPoint(x: a.x, y: b.y), b]
    }
  }

  static func along(_ pts: [CGPoint], _ f: CGFloat) -> CGPoint {
    let segs = zip(pts, pts.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
    var left = segs.reduce(0, +) * min(1, max(0, f))
    for (i, s) in segs.enumerated() {
      if left <= s || i == segs.count - 1 {
        let t = s > 0 ? min(1, left / s) : 0
        return CGPoint(x: pts[i].x + (pts[i + 1].x - pts[i].x) * t, y: pts[i].y + (pts[i + 1].y - pts[i].y) * t)
      }
      left -= s
    }
    return pts[0]
  }

  static func elbow(_ a: CGPoint, _ b: CGPoint, _ route: Route, _ r: CGFloat) -> Path {
    var p = Path()
    p.move(to: a)
    let dx = b.x - a.x, dy = b.y - a.y
    let sx: CGFloat = dx < 0 ? -1 : 1, sy: CGFloat = dy < 0 ? -1 : 1
    switch route {
    case .straight:
      p.addLine(to: b)
    case .curve:
      let m = (a.x + b.x) / 2
      p.addCurve(to: b, control1: CGPoint(x: m, y: a.y), control2: CGPoint(x: m, y: b.y))
    case .step:
      let m = (a.x + b.x) / 2
      let k = min(r, abs(dx) / 2, abs(dy) / 2)
      p.addLine(to: CGPoint(x: m - sx * k, y: a.y))
      p.addQuadCurve(to: CGPoint(x: m, y: a.y + sy * k), control: CGPoint(x: m, y: a.y))
      p.addLine(to: CGPoint(x: m, y: b.y - sy * k))
      p.addQuadCurve(to: CGPoint(x: m + sx * k, y: b.y), control: CGPoint(x: m, y: b.y))
      p.addLine(to: b)
    case .h:
      let k = min(r, abs(dx), abs(dy))
      p.addLine(to: CGPoint(x: b.x - sx * k, y: a.y))
      p.addQuadCurve(to: CGPoint(x: b.x, y: a.y + sy * k), control: CGPoint(x: b.x, y: a.y))
      p.addLine(to: b)
    case .v:
      let k = min(r, abs(dx), abs(dy))
      p.addLine(to: CGPoint(x: a.x, y: b.y - sy * k))
      p.addQuadCurve(to: CGPoint(x: a.x + sx * k, y: b.y), control: CGPoint(x: a.x, y: b.y))
      p.addLine(to: b)
    }
    return p
  }

  static func head(_ p: CGPoint, _ q: CGPoint) -> Path {
    let len = max(hypot(q.x - p.x, q.y - p.y), 0.001)
    let ux = (q.x - p.x) / len, uy = (q.y - p.y) / len
    var path = Path()
    path.move(to: CGPoint(x: q.x - ux * 6 - uy * 4, y: q.y - uy * 6 + ux * 4))
    path.addLine(to: q)
    path.addLine(to: CGPoint(x: q.x - ux * 6 + uy * 4, y: q.y - uy * 6 - ux * 4))
    return path
  }
}
