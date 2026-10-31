import SwiftUI

/// When a stage plays its script.
public enum Play: Sendable {
  /// Repeats while on screen, resetting to `initial` between runs.
  case loop
  /// Plays once when first seen, then holds the end. Leaving the screen
  /// before the end resets it; a finished scene stays finished.
  case once
}

/// A second design for narrow containers: below `below` points of
/// container width the stage shows this size and `layout` is `.compact`.
public struct CompactDesign: Sendable, Equatable {
  /// Container widths under this use the compact design.
  public var below: CGFloat
  /// The compact design size.
  public var size: CGSize
  /// Creates a compact design.
  public init(below: CGFloat, width: CGFloat, height: CGFloat) {
    self.below = below
    self.size = CGSize(width: width, height: height)
  }
}

/// The touch cursor: a soft dot where a finger taps or drags, nothing in
/// between. `at` is where it rests at the start of each run.
public struct StageCursor: Sendable, Equatable {
  /// Where the touch point starts each run.
  public var at: Target
  /// Creates a touch cursor resting at `at`.
  public init(at: Target) { self.at = at }
}

/// The canvas: a fixed design size scaled to fit its container's width,
/// scene state changed by a script, and a touch cursor drawn over it.
///
/// - `content` draws the scene from its state. Mark views with
///   `.target(_:)` to measure and aim at them.
/// - `overlay` draws what is placed from measured rects (a connector, a
///   note under a card). It runs on every frame the rects change, so it
///   follows targets while they animate. Targets inside it are not measured.
///
/// The script runs only while the stage is on screen and the app is in
/// the foreground. (Not `scenePhase`: it reads `.background` for a stage
/// hosted in a UIKit window.) Under Reduce Motion, or with no script, the stage shows `poster`
/// (or `initial`). The scene is a fixed picture: Dynamic Type does not
/// change it, and the whole stage scales down to fit narrow containers.
@MainActor
public struct Stage<S: Equatable, Content: View, Overlay: View>: View {
  let size: CGSize
  let compact: CompactDesign?
  let initial: S
  let poster: S?
  let script: Script<S>?
  let play: Play
  let speed: Double
  let clock: any Clock<Duration>
  let cursor: StageCursor?
  let fidelity: Fidelity
  let accent: Color?
  let label: String?
  let content: (S, StageLayout) -> Content
  let overlay: (S, Rects, StageLayout) -> Overlay

  @State private var model: StageModel<S>
  @State private var store = RectStore()
  @State private var touch = CursorModel()
  @State private var width: CGFloat?
  @State private var onScreen = false
  @State private var scrollVisible = true
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var foreground = UIApplication.shared.applicationState != .background
  @Environment(\.colorScheme) private var scheme
  @Environment(\.stageRecorder) private var recorder

  /// Creates a stage.
  ///
  /// - Parameters:
  ///   - width: Design width in points.
  ///   - height: Design height in points.
  ///   - compact: A second design for narrow containers.
  ///   - initial: Scene state at the start of each run.
  ///   - poster: The still shown under Reduce Motion or with no script:
  ///     the beat that tells the story on its own. Defaults to `initial`.
  ///   - play: Loop while on screen, or play once.
  ///   - speed: Plays the script faster (above 1) or slower.
  ///   - clock: The clock waits and tweens run on.
  ///   - cursor: A touch cursor, or `nil` for none.
  ///   - fidelity: How much of the scene is real words.
  ///   - accent: The accent color, over the look's.
  ///   - accessibilityLabel: One summary VoiceOver reads for the whole
  ///     scene. `nil` hides a decorative scene from VoiceOver.
  ///   - script: The story.
  ///   - content: The scene, from its state.
  ///   - overlay: Views placed from measured rects.
  public init(
    width: CGFloat, height: CGFloat, compact: CompactDesign? = nil,
    initial: S, poster: S? = nil, play: Play = .loop, speed: Double = 1,
    clock: any Clock<Duration> = ContinuousClock(), cursor: StageCursor? = nil,
    fidelity: Fidelity = .standard, accent: Color? = nil, accessibilityLabel: String? = nil,
    script: Script<S>? = nil,
    @ViewBuilder content: @escaping (S, StageLayout) -> Content,
    @ViewBuilder overlay: @escaping (S, Rects, StageLayout) -> Overlay
  ) {
    self.size = CGSize(width: width, height: height)
    self.compact = compact
    self.initial = initial
    self.poster = poster
    self.script = script
    self.play = play
    self.speed = speed
    self.clock = clock
    self.cursor = cursor
    self.fidelity = fidelity
    self.accent = accent
    self.label = accessibilityLabel
    self.content = content
    self.overlay = overlay
    _model = State(initialValue: StageModel(state: initial))
  }

  private var still: Bool { script == nil || reduceMotion }

  private var layout: StageLayout {
    guard let compact, let width, width < compact.below else { return .wide }
    return .compact
  }

  private var design: CGSize { layout == .compact ? compact!.size : size }

  private var runKey: RunKey {
    RunKey(run: !still && !model.done && onScreen && scrollVisible && foreground && width != nil, still: still, layout: layout)
  }

  public var body: some View {
    let design = self.design
    let scale = width.map { min(1, $0 / design.width) } ?? 1
    let _ = model.recorder = recorder
    Color.clear
      .frame(maxWidth: .infinity)
      .frame(height: design.height * scale)
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
      .overlay(alignment: .top) {
        scene(design)
          .frame(width: design.width, height: design.height)
          .scaleEffect(scale, anchor: .top)
          .opacity(width == nil ? 0 : 1)
      }
      .onAppear { onScreen = true }
      .onDisappear { onScreen = false }
      .onScrollVisibilityChange(threshold: 0.01) { scrollVisible = $0 }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in foreground = false }
      .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in foreground = true }
      .onChange(of: runKey, initial: true) { _, key in drive(key) }
      // A removed stage gets no more onChange calls, so stop its run here,
      // unless it reappeared in the same turn (SwiftUI does that on setup).
      .onDisappear { Task { @MainActor in if !onScreen { model.stop() } } }
      .modifier(StageAccessibility(label: label))
  }

  private func scene(_ design: CGSize) -> some View {
    let look = (scheme == .dark ? StageLook.dark : .light)
    let layout = self.layout
    return ZStack(alignment: .topLeading) {
      content(model.state, layout)
      GenCarrier(gen: model.gen)
    }
    .frame(width: design.width, height: design.height, alignment: .topLeading)
    .transaction { t in if model.instant.contains(StageModel<S>.wholeStage) { t.disablesAnimations = true; t.animation = nil } }
    .environment(\.stageInstantScopes, model.instant)
    .environment(\.stageInstant, model.instant.contains(StageModel<S>.wholeStage))
    .environment(\.stagePressed, model.pressed)
    .overlayPreferenceValue(CaretKey.self) { carets in
      GeometryReader { proxy in
        let _ = store.setChars(carets.mapValues { $0.resolve(proxy) })
        Color.clear
      }
    }
    .overlayPreferenceValue(TargetsKey.self) { targets in
      GeometryReader { proxy in
        let rects = Rects(targets.anchors.mapValues { proxy[$0] })
        let _ = store.publish(gen: targets.gen, rects: rects)
        // Never statically empty: SwiftUI skips a preference reader whose
        // content is EmptyView, and then nothing would publish.
        ZStack(alignment: .topLeading) {
          Color.clear
          overlay(model.state, rects, layout)
        }
        .frame(width: design.width, height: design.height, alignment: .topLeading)
      }
    }
    .overlay(alignment: .topLeading) {
      if cursor != nil, !still { TouchDot(model: touch) }
    }
    .background { StageProbe(model: model) }
    .clipped()
    .environment(\.stageLook, accent.map { look.accent($0) } ?? look)
    .environment(\.stageFidelity, fidelity)
    .environment(\.stageStill, still)
    .environment(\.stageLayout, layout)
    .dynamicTypeSize(.large)
  }

  private func reset(to state: S) {
    var t = Transaction()
    t.disablesAnimations = true
    withTransaction(t) {
      model.state = state
      model.gen += 1
      model.mark = nil
      model.pressed = []
      touch.reset()
    }
  }

  private func rest() {
    guard let cursor else { return }
    let act = makeAct(onMark: { _ in })
    if let p = try? act.resolve(cursor.at) { touch.position = p }
  }

  private func makeAct(onMark: @escaping (Mark) -> Void) -> Act<S> {
    model.designSize = design
    return Act(layout: layout, model: model, store: store, cursor: touch, clock: ClockBox(clock), speed: speed, finger: cursor != nil, onMark: onMark)
  }

  // One run per key: a new key cancels the old run and starts the next.
  // A view that disappears and reappears with the same key keeps its run.
  private func drive(_ key: RunKey) {
    debugLog("drive \(key)")
    if key == model.runKey, model.runTask != nil { return }
    model.stop()
    model.runKey = key
    if key.still {
      reset(to: poster ?? initial)
      return
    }
    if !model.done { reset(to: initial) }
    guard key.run, script != nil else { return }
    let id = model.nextRun()
    model.runTask = Task { await run(id) }
  }

  private func run(_ id: Int) async {
    guard let script else { return }
    model.marks = []
    do {
      // The first publish places targets the cursor's rest point may name.
      try await store.published(model.gen)
      repeat {
        rest()
        let act = makeAct { mark in
          model.marks.append(mark)
          debugLog("mark \(mark.name) t=\(mark.time)")
          model.recorder?.record(mark, model: model)
        }
        try await script(act)
        guard play == .loop else { break }
        try Task.checkCancellation()
        reset(to: initial)
        model.marks = []
        try await store.published(model.gen)
      } while true
      if model.run == id {
        model.done = true
        model.runTask = nil
      }
    } catch is CancellationError {
      // drive() already reset the scene for whatever comes next.
    } catch {
      // A real error in the script: report it once and stand the stage down.
      FileHandle.standardError.write(Data("[benjify] script error: \(error)\n".utf8))
      if model.run == id { model.runTask = nil }
    }
  }
}

extension Stage where Overlay == EmptyView {
  /// Creates a stage with no overlay. See the full initializer.
  public init(
    width: CGFloat, height: CGFloat, compact: CompactDesign? = nil,
    initial: S, poster: S? = nil, play: Play = .loop, speed: Double = 1,
    clock: any Clock<Duration> = ContinuousClock(), cursor: StageCursor? = nil,
    fidelity: Fidelity = .standard, accent: Color? = nil, accessibilityLabel: String? = nil,
    script: Script<S>? = nil,
    @ViewBuilder content: @escaping (S, StageLayout) -> Content
  ) {
    self.init(width: width, height: height, compact: compact, initial: initial, poster: poster, play: play, speed: speed, clock: clock, cursor: cursor, fidelity: fidelity, accent: accent, accessibilityLabel: accessibilityLabel, script: script, content: content, overlay: { _, _, _ in EmptyView() })
  }
}

struct RunKey: Hashable {
  var run: Bool
  var still: Bool
  var layout: StageLayout
}

/// Scene state and what the act changes besides it. Observed by the stage.
@MainActor @Observable
final class StageModel<S: Equatable> {
  static var wholeStage: String { "\u{0}stage" }
  var state: S
  var gen = 0
  var instant: Set<String> = []
  var pressed: Set<String> = []
  var mark: String?
  @ObservationIgnored var marks: [Mark] = []
  @ObservationIgnored var designSize: CGSize = .zero
  @ObservationIgnored weak var view: UIView?
  @ObservationIgnored var recorder: StageRecorder?
  var done = false
  @ObservationIgnored var runKey: RunKey?
  @ObservationIgnored var runTask: Task<Void, Never>?
  @ObservationIgnored private(set) var run = 0

  func nextRun() -> Int {
    run += 1
    return run
  }

  func stop() {
    runTask?.cancel()
    runTask = nil
    runKey = nil
    run += 1
  }
  init(state: S) { self.state = state }
}

// The body's generation, published beside the anchors it was drawn with.
struct GenCarrier: View {
  let gen: Int
  var body: some View {
    Color.clear.frame(width: 0, height: 0).preference(key: TargetsKey.self, value: Targets(gen: gen))
  }
}

private struct StageAccessibility: ViewModifier {
  let label: String?
  func body(content: Content) -> some View {
    if let label {
      content.accessibilityElement(children: .ignore).accessibilityLabel(Text(label)).accessibilityAddTraits(.isImage)
    } else {
      content.accessibilityHidden(true)
    }
  }
}

// Finds the stage's UIKit view, so a recorder can capture its region.
private struct StageProbe<S: Equatable>: UIViewRepresentable {
  let model: StageModel<S>
  func makeUIView(context: Context) -> UIView {
    let v = UIView()
    v.isUserInteractionEnabled = false
    model.view = v
    return v
  }
  func updateUIView(_ view: UIView, context: Context) { model.view = view }
}

extension EnvironmentValues {
  /// Targets being pressed by the touch cursor right now.
  @Entry public var stagePressed: Set<String> = []
  @Entry var stageInstantScopes: Set<String> = []
  @Entry var stageInstant: Bool = false
}

func debugLog(_ s: @autoclosure () -> String) {
  guard ProcessInfo.processInfo.environment["BENJIFY_DEBUG"] != nil else { return }
  FileHandle.standardError.write(Data(("[benjify] " + s() + "\n").utf8))
}
