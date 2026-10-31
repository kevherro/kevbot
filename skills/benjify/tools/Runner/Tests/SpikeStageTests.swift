import SwiftUI
import Testing
import UIKit
@testable import StageshowKit

// Spike results that live inside a stage: text rects and caret, the
// awaitable set(), and how anchors behave. Each test names the behavior.

@MainActor
@Suite(.serialized)
struct TextSpike {
  struct S: Equatable { var text: String }

  // Every dark pixel the text draws lies inside some character's box.
  func inkCoverage(_ text: String, font: Font = .system(size: 22)) async throws -> (inside: Int, total: Int, chars: Int) {
    var result = (0, 0, 0)
    try await Harness.run(S(text: text), width: 400, height: 200) { s, _ in
      Text(s.text).font(font).foregroundStyle(.black).frame(width: 360, alignment: .leading).caretTarget("t")
        .padding(20)
    } script: { a in
      try await a.wait(.milliseconds(200))
      let chars = a.store.chars["t"] ?? []
      let window = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!.windows.first { $0.windowLevel == .alert + 1 && !$0.isHidden }!
      let px = Pixels(Host.capture(window))
      guard let box = a.rect("t") else { return }
      var inside = 0, total = 0
      for y in Int(box.minY * px.scale)..<Int(box.maxY * px.scale) {
        for x in Int(box.minX * px.scale)..<Int(box.maxX * px.scale) where Pixels.isDark(px.rgb(x, y)) {
          total += 1
          let p = CGPoint(x: CGFloat(x) / px.scale, y: CGFloat(y) / px.scale)
          if chars.contains(where: { $0.rect.insetBy(dx: -0.5, dy: -0.5).contains(p) }) { inside += 1 }
        }
      }
      result = (inside, total, chars.count)
    }
    return result
  }

  @Test func layoutRectsHoldAllInk() async throws {
    let r = try await inkCoverage("The quick brown fox jumps over the lazy dog")
    print("MEASURE text.ink latin inside=\(r.inside)/\(r.total) chars=\(r.chars)")
    #expect(r.total > 500)
    #expect(r.inside == r.total)
  }

  // Not covered by the spike: recorded, not asserted, so the skill can say
  // what holds.
  @Test(arguments: [("emoji", "Ship it 👍🏽 now 🇨🇦"), ("ligature", "office affine ffl"), ("rtl", "שלום עולם مرحبا"), ("mixed", "Bold and light")])
  func layoutRectsUntestedScripts(_ c: (String, String)) async throws {
    let font: Font = c.0 == "mixed" ? .system(size: 22, weight: .heavy) : .system(size: 22)
    let r = try await inkCoverage(c.1, font: font)
    print("MEASURE text.ink \(c.0) inside=\(r.inside)/\(r.total) chars=\(r.chars) of \(c.1.count) graphemes, \(c.1.utf16.count) utf16")
    #expect(r.total > 0)
  }

  @Test func caretSixCases() async throws {
    // Two lines, split by a newline: "Hello world" is offsets 0-10, the
    // newline is 11, "Second line" is 12-22.
    var got: [String: Int] = [:]
    try await Harness.run(S(text: "Hello world\nSecond line"), width: 400, height: 200) { s, _ in
      Text(s.text).font(.system(size: 22)).frame(width: 360, alignment: .leading).caretTarget("t").padding(20)
    } script: { a in
      try await a.wait(.milliseconds(200))
      let chars = a.store.chars["t"] ?? []
      print("MEASURE text.caretOffsets \(chars.map(\.offset))")
      guard chars.contains(where: { $0.offset == 12 }) else { return }
      let line1 = chars.first { $0.offset == 0 }!.rect, line2 = chars.first { $0.offset == 12 }!.rect
      let w = chars.first { $0.offset == 6 }!.rect
      got["above"] = a.caret("t", at: CGPoint(x: 100, y: line1.minY - 10))
      got["below"] = a.caret("t", at: CGPoint(x: 100, y: line2.maxY + 10))
      got["leftOfLine2"] = a.caret("t", at: CGPoint(x: 0, y: line2.midY))
      got["rightOfLine1"] = a.caret("t", at: CGPoint(x: 390, y: line1.midY))
      got["betweenNearLine1"] = a.caret("t", at: CGPoint(x: 0, y: (line1.midY + line2.midY) / 2 - 2))
      got["rightHalfOfW"] = a.caret("t", at: CGPoint(x: w.midX + 1, y: w.midY))
    }
    print("MEASURE text.caret \(got)")
    #expect(got == ["above": 0, "below": 23, "leftOfLine2": 12, "rightOfLine1": 11, "betweenNearLine1": 0, "rightHalfOfW": 7])
  }
}

@MainActor
@Suite(.serialized)
struct SetSpike {
  struct S: Equatable { var x: CGFloat = 0; var show = false; var wide = false }

  @Test func threeHundredSetsReturnFreshRects() async throws {
    var fresh = 0
    var waits: [Double] = []
    try await Harness.run(S(), width: 400, height: 100) { s, _ in
      HStack(spacing: 0) {
        Color.clear.frame(width: s.x, height: 10)
        Color.red.frame(width: 20, height: 20).target("box")
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    } script: { a in
      let clock = ContinuousClock()
      for i in 1...300 {
        let x = CGFloat(i % 300)
        let t0 = clock.now
        try await a.set { $0.x = x }
        waits.append((t0.duration(to: clock.now)).seconds * 1000)
        if a.rect("box")?.minX == x { fresh += 1 }
      }
    }
    let sorted = waits.sorted()
    print("MEASURE set.runs \(Harness.lastRuns)")
    print("MEASURE set.fresh \(fresh)/300 waitMedian=\(String(format: "%.2f", sorted[150]))ms p95=\(String(format: "%.2f", sorted[285]))ms max=\(String(format: "%.2f", sorted.last!))ms")
    #expect(fresh == 300)
  }

  @Test func readerSeesEveryPublishOnChangeDoesNot() async throws {
    // Ten animated changes, read two ways: the reader closure (what the kit
    // uses) and onChange of the measured value.
    final class Counts { var reader: Set<Int> = []; var onChange: Set<Int> = []; var onChangeOf: Set<Int> = [] }
    let counts = Counts()
    struct Probe: View {
      let gen: Int
      let counts: Counts
      var body: some View {
        Color.red.frame(width: 20, height: 20).offset(x: CGFloat(gen) * 10)
          .onGeometryChange(for: Int.self) { _ in gen } action: { counts.onChange.insert($0) }
          .background(GeometryReader { proxy in
            let _ = counts.reader.insert(gen)
            Color.clear.onChange(of: gen) { _, g in counts.onChangeOf.insert(g) }
          })
      }
    }
    struct Host2: View {
      @State var gen = 0
      let counts: Counts
      var body: some View {
        Probe(gen: gen, counts: counts).task {
          for i in 1...10 { withAnimation(.easeOut(duration: 0.3)) { gen = i }; try? await Task.sleep(for: .milliseconds(1)) }
        }
      }
    }
    let w = Host.show(Host2(counts: counts))
    await Host.pause(600)
    w.isHidden = true
    print("MEASURE set.deliveries reader=\(counts.reader.count - 1)/10 onGeometryChange=\(counts.onChange.count)/10 onChangeOf=\(counts.onChangeOf.count)/10")
    #expect(counts.reader.isSuperset(of: Set(1...10)))
  }

  // The spike saw an animated insert one publish late (20 of 20). On iOS 27
  // (24A434) in Swift 6 mode the publish set() waits for already has it.
  @Test func animatedInsertPresentWhenSetReturns() async throws {
    var lateAfterSet = 0, presentAfterNext = 0
    try await Harness.run(S(), width: 400, height: 100) { s, _ in
      VStack {
        if s.show { Color.blue.frame(width: 20, height: 20).target("late").transition(.opacity) }
        Color.red.frame(width: 20, height: 20).target("base")
      }
      .animation(.easeOut(duration: 0.2), value: s.show)
    } script: { a in
      for _ in 0..<20 {
        try await a.set { $0.show = true }
        if a.rect("late") == nil { lateAfterSet += 1 }
        let n = a.store.publishes
        while a.store.publishes == n { try await Task.sleep(for: .milliseconds(1)) }
        if a.rect("late") != nil { presentAfterNext += 1 }
        try await a.snap { $0.show = false }
        try await a.wait(.milliseconds(50))
      }
    }
    print("MEASURE set.animatedInsert lateAfterSet=\(lateAfterSet)/20 presentNextPublish=\(presentAfterNext)/20")
    #expect(lateAfterSet == 0)
    #expect(presentAfterNext == 20)
  }

  @Test func rectsFollowAnimatedLayout() async throws {
    var widths: [CGFloat] = []
    try await Harness.run(S(), width: 400, height: 100) { s, _ in
      Color.red.frame(width: s.wide ? 300 : 100, height: 20).target("bar")
        .animation(.linear(duration: 0.6), value: s.wide)
    } script: { a in
      try await a.set { $0.wide = true }
      for _ in 0..<5 {
        try await a.wait(.milliseconds(100))
        widths.append(a.rect("bar")?.width ?? -1)
      }
    }
    print("MEASURE anchors.followLayout widths=\(widths.map { Int($0) })")
    #expect(widths.allSatisfy { $0 > 100 && $0 < 300 })
    #expect(widths == widths.sorted())
  }

  @Test func effectsBeforeTargetExcludedAfterIncluded() async throws {
    var before: CGRect?, after: CGRect?
    try await Harness.run(S(), width: 400, height: 200) { _, _ in
      VStack(spacing: 0) {
        Color.red.frame(width: 20, height: 20).offset(x: 50).scaleEffect(2).target("before")
        Color.red.frame(width: 20, height: 20).target("after").offset(x: 50).scaleEffect(2)
      }
      .frame(width: 200, height: 100)
    } script: { a in
      try await a.wait(.milliseconds(100))
      before = a.rect("before")
      after = a.rect("after")
    }
    print("MEASURE anchors.effects before=\(before!) after=\(after!)")
    #expect(before!.width == 20)
    #expect(after!.width == 40)
    #expect(after!.minX > before!.minX + 50)
  }

  // The spike saw set() never resolve off screen. Here it resolves in a
  // window moved past the screen edge and in a hidden window. (Scrolled out
  // of a ScrollView, the stage cancels its own run: see StageTests.)
  // Cancellation ends a pending wait either way.
  @Test(arguments: ["moved", "hidden"])
  func offscreenSet(_ how: String) async throws {
    var outcome = "none"
    var released = Double.infinity
    var window: UIWindow?
    await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
      let stage = Stage(width: 200, height: 100, initial: S(), play: .once, script: { a in
        let w = window!
        try? await a.wait(.milliseconds(100))
        if how == "moved" { w.frame.origin.y = 5000 } else if how == "hidden" { w.isHidden = true }
        let ask = ContinuousClock.now
        let wait = Task { @MainActor in try await a.set { $0.x = 99 } }
        try? await Task.sleep(for: .milliseconds(800))
        outcome = a.store.gen >= a.model.gen ? "resolved" : "pending"
        wait.cancel()
        _ = try? await wait.value
        released = (ContinuousClock.now - ask).seconds * 1000 - 800
        done.resume()
      }) { s, _ in Color.red.frame(width: 20, height: 20).offset(x: s.x).target("box") }
      window = how == "scrolled"
        ? Host.show(ScrollView { VStack(spacing: 0) { Color.clear.frame(height: 3000); stage } })
        : Host.show(stage)
    }
    window?.isHidden = true
    print("MEASURE set.offscreen.\(how) outcome=\(outcome) cancelReleasedIn=\(String(format: "%.1f", released))ms")
    #expect(outcome == "resolved")
    #expect(released < 50)
  }
}

// Behaviors found while building the kit on iOS 27 (not in the spike).
@MainActor
@Suite(.serialized)
struct KitFoundSpike {
  struct K: PreferenceKey {
    static let defaultValue = 0
    static func reduce(value: inout Int, nextValue: () -> Int) { value += nextValue() }
  }
  @MainActor final class Hits { var n = 0 }

  // A preference reader whose content is statically empty is never called.
  // The stage's reader always draws a Color.clear for this reason.
  @Test func readerWithEmptyContentIsSkipped() async {
    let empty = Hits(), clear = Hits()
    let v = VStack {
      Color.red.frame(width: 10, height: 10).preference(key: K.self, value: 1)
        .overlayPreferenceValue(K.self) { _ in GeometryReader { _ in let _ = empty.n += 1; EmptyView() } }
      Color.red.frame(width: 10, height: 10).preference(key: K.self, value: 1)
        .overlayPreferenceValue(K.self) { _ in GeometryReader { _ in let _ = clear.n += 1; Color.clear } }
    }
    let w = Host.show(v)
    await Host.pause(300)
    w.isHidden = true
    print("MEASURE found.emptyReader emptyCalls=\(empty.n) clearCalls=\(clear.n)")
    #expect(empty.n == 0)
    #expect(clear.n > 0)
  }

  // anchorPreference replaces what its subtree published; a target holding
  // a target needs transformAnchorPreference, which the kit uses.
  @Test func nestedTargetsBothMeasured() async throws {
    struct S: Equatable {}
    var names: [String] = []
    try await Harness.run(S(), width: 200, height: 100) { _, _ in
      Color.gray.frame(width: 100, height: 50).overlay(Color.red.frame(width: 10, height: 10).target("inner")).target("outer")
    } script: { a in
      try await a.wait(.milliseconds(100))
      names = a.store.rects.byName.keys.sorted()
    }
    #expect(names == ["inner", "outer"])
  }

  // scenePhase reads .background for SwiftUI hosted in a UIKit window, so
  // the stage follows the app's foreground notifications instead.
  @Test func scenePhaseIsBackgroundInUIKitHost() async {
    @MainActor final class Seen { var phase: ScenePhase? }
    struct V: View {
      @Environment(\.scenePhase) var phase
      let seen: Seen
      var body: some View { let _ = seen.phase = phase; Color.clear }
    }
    let seen = Seen()
    let w = Host.show(V(seen: seen))
    await Host.pause(200)
    w.isHidden = true
    print("MEASURE found.scenePhase \(String(describing: seen.phase)) app=\(UIApplication.shared.applicationState.rawValue)")
    #expect(seen.phase == .background)
    #expect(UIApplication.shared.applicationState != .background)
  }
}
