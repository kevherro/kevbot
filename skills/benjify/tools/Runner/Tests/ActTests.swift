import SwiftUI
import Testing
import UIKit
@testable import StageshowKit

// One test per behavior of upstream act.ts that a script can observe,
// driven through a real Stage in the runner's window scene.

@MainActor
@Suite(.serialized)
struct ActTests {
  struct S: Equatable { var x: CGFloat = 0; var on = false; var text = ""; var n = 0 }

  // A scene with a target at a known place, and a slow implicit animation
  // on `on` (the CSS-transition stand-in).
  @ViewBuilder static func scene(_ s: S) -> some View {
    ZStack(alignment: .topLeading) {
      Color.red.frame(width: 40, height: 20).target("box").offset(x: 100, y: 50)
      Color.blue.frame(width: s.on ? 200 : 100, height: 10).target("bar")
        .animation(.linear(duration: 1), value: s.on)
        .offset(y: 150)
      Color.green.frame(width: s.on ? 200 : 100, height: 10)
        .animation(.linear(duration: 1), value: s.on)
        .target("scoped").offset(y: 200)
    }
  }

  @Test func putChangesStateWithoutWaiting() async throws {
    var seenGen = (before: 0, after: 0, published: 0)
    try await Harness.run(S()) { s, _ in Self.scene(s) } script: { a in
      try await a.wait(.milliseconds(50))
      seenGen.before = a.model.gen
      a.put { $0.n = 1 }
      seenGen.after = a.model.gen
      seenGen.published = a.store.gen
    }
    #expect(seenGen.after == seenGen.before + 1)
    #expect(seenGen.published < seenGen.after)
  }

  @Test func setReturnsAfterTheChangeIsMeasured() async throws {
    var width: CGFloat?
    try await Harness.run(S()) { s, _ in
      Color.red.frame(width: 10 + s.x, height: 10).target("grow")
    } script: { a in
      try await a.set { $0.x = 90 }
      width = a.rect("grow")?.width
    }
    #expect(width == 100)
  }

  @Test func snapSkipsAnimationsEverywhereOrInScope() async throws {
    var whole: CGFloat?, scopedIn: CGFloat?, scopedOut: CGFloat?
    try await Harness.run(S()) { s, _ in Self.scene(s) } script: { a in
      try await a.snap { $0.on = true }
      try await a.wait(.milliseconds(50))
      whole = a.rect("bar")?.width
      try await a.snap { $0.on = false }
      try await a.snap({ $0.on = true }, scope: "scoped")
      try await a.wait(.milliseconds(100))
      scopedIn = a.rect("scoped")?.width
      scopedOut = a.rect("bar")?.width
    }
    #expect(whole == 200)
    #expect(scopedIn == 200)
    #expect(scopedOut.map { $0 > 100 && $0 < 200 } == true)
  }

  @Test func waitRunsOnTheInjectedClockDividedBySpeed() async throws {
    let clock = ManualClock()
    var log: [String] = []
    let stage = Stage(width: 200, height: 100, initial: S(), play: .once, speed: 2, clock: clock) { a in
      log.append("start")
      try await a.wait(.seconds(1))
      log.append("waited")
    } content: { s, _ in Self.scene(s) }
    let w = Host.show(stage)
    defer { w.isHidden = true }
    await Host.pause(200)
    #expect(log == ["start"])
    clock.advance(by: .milliseconds(499))
    await Host.pause(50)
    #expect(log == ["start"])
    clock.advance(by: .milliseconds(1))
    await Host.pause(50)
    #expect(log == ["start", "waited"])
  }

  @Test func rectIsNilForAMissingTarget() async throws {
    var missing: CGRect? = .zero, box: CGRect?
    try await Harness.run(S()) { s, _ in Self.scene(s) } script: { a in
      try await a.wait(.milliseconds(50))
      missing = a.rect("nope")
      box = a.rect("box")
    }
    #expect(missing == nil)
    #expect(box == CGRect(x: 100, y: 50, width: 40, height: 20))
  }

  @Test func centerResolvesEveryTargetForm() async throws {
    var got: [CGPoint] = []
    var thrown: StageError?
    try await Harness.run(S()) { s, _ in Self.scene(s) } script: { a in
      try await a.wait(.milliseconds(50))
      got.append(try a.center("box"))
      got.append(try a.center(.at("box", x: 0, y: 1)))
      got.append(try a.center(.point(CGPoint(x: 7, y: 8))))
      got.append(try a.center(.perLayout(wide: .point(CGPoint(x: 1, y: 1)), compact: "box")))
      do { _ = try a.center("nope") } catch let e as StageError { thrown = e }
    }
    #expect(got == [CGPoint(x: 120, y: 60), CGPoint(x: 100, y: 70), CGPoint(x: 7, y: 8), CGPoint(x: 1, y: 1)])
    #expect(thrown == .noTarget("nope"))
  }

  @Test func moveArcsToTheTargetTimedByDistance() async throws {
    var points: [CGPoint] = []
    var ms = 0.0
    var end = CGPoint.zero
    try await Harness.run(S(), cursor: true) { s, _ in Self.scene(s) } script: { a in
      try a.place(.point(CGPoint(x: 0, y: 60)))
      let t0 = ContinuousClock.now
      try await a.move(to: "box", onMove: { p, _, _ in points.append(p) })
      ms = (ContinuousClock.now - t0).seconds * 1000
      end = a.cursor.position
    }
    // 120pt: 260 + 0.9 * 120 = 368ms. The arc bows off the straight line.
    #expect(end == CGPoint(x: 120, y: 60))
    #expect(ms > 360 && ms < 460)
    #expect(points.contains { abs($0.y - 60) > 2 })
  }

  @Test func movePathReplacesTheArc() async throws {
    var points: [CGPoint] = []
    try await Harness.run(S(), cursor: true) { s, _ in Self.scene(s) } script: { a in
      try a.place(.point(CGPoint(x: 0, y: 0)))
      try await a.move(to: .point(CGPoint(x: 100, y: 0)), duration: .milliseconds(200), path: { e, f, t in
        CGPoint(x: f.x + (t.x - f.x) * e, y: 30)
      }, onMove: { p, _, _ in points.append(p) })
    }
    #expect(points.allSatisfy { $0.y == 30 })
  }

  @Test func clickShowsTheFingerAndPressesTheTarget() async throws {
    @MainActor final class Seen { var pressed: Set<String> = []; var touching = false }
    let seen = Seen()
    var ms = 0.0
    try await Harness.run(S(), cursor: true) { s, _ in
      PressProbe(seen: { seen.pressed.formUnion($0) })
      Self.scene(s)
    } script: { a in
      try a.place("box")
      let t0 = ContinuousClock.now
      Task { @MainActor in
        while !Task.isCancelled { if a.cursor.touching { seen.touching = true }; try await Task.sleep(for: .milliseconds(5)) }
      }
      try await a.click("box")
      ms = (ContinuousClock.now - t0).seconds * 1000
    }
    // Already on the box: no travel, then 120 settle + 140 finger + 100 press.
    #expect(seen.pressed == ["box"])
    #expect(seen.touching)
    #expect(ms > 350 && ms < 450)
  }

  struct PressProbe: View {
    let seen: (Set<String>) -> Void
    @Environment(\.stagePressed) var pressed
    var body: some View { let _ = seen(pressed); Color.clear.frame(width: 1, height: 1) }
  }

  @Test func doubleClickPressesTwice() async throws {
    var presses = 0
    var was = false
    try await Harness.run(S(), cursor: true) { s, _ in Self.scene(s) } script: { a in
      try a.place("box")
      let watch = Task { @MainActor in
        while !Task.isCancelled {
          if a.cursor.pressed && !was { presses += 1 }
          was = a.cursor.pressed
          try await Task.sleep(for: .milliseconds(2))
        }
      }
      try await a.click(double: true)
      watch.cancel()
    }
    #expect(presses == 2)
  }

  @Test func dragCarriesToTheTargetAndLifts() async throws {
    var points: [CGPoint] = []
    var afterLift = (pressed: true, swiping: true)
    try await Harness.run(S(), cursor: true) { s, _ in Self.scene(s) } script: { a in
      try a.place(.point(CGPoint(x: 10, y: 10)))
      try await a.drag(to: "box", onMove: { p, _, _ in points.append(p) })
      afterLift = (a.cursor.pressed, a.cursor.swiping)
    }
    #expect(points.last == CGPoint(x: 120, y: 60))
    #expect(points.count > 10)
    #expect(afterLift == (false, false))
  }

  @Test func typeAddsOneCharacterAtATime() async throws {
    var seen: [String] = []
    try await Harness.run(S()) { s, _ in
      Text(s.text).onChange(of: s.text) { _, t in seen.append(t) }
    } script: { a in
      try await a.type(\.text, "maya")
    }
    #expect(seen == ["m", "ma", "may", "maya"])
  }

  @Test func staggerStartsItemsGapApartAndWaitsForAll() async throws {
    var starts: [Double] = []
    var finished = 0
    try await Harness.run(S()) { s, _ in Self.scene(s) } script: { a in
      let t0 = ContinuousClock.now
      try await a.stagger([0, 1, 2, 3], gap: .milliseconds(100)) { _, _ in
        starts.append((ContinuousClock.now - t0).seconds * 1000)
        try await a.wait(.milliseconds(50))
        finished += 1
      }
    }
    #expect(finished == 4)
    #expect(starts.count == 4)
    for (i, t) in starts.enumerated() { #expect(abs(t - Double(i) * 100) < 30) }
  }

  @Test func markRecordsNameTimeAndRects() async throws {
    var marks: [Mark] = []
    try await Harness.run(S()) { s, _ in Self.scene(s) } script: { a in
      try await a.wait(.milliseconds(200))
      a.mark("one")
      try await a.wait(.milliseconds(300))
      a.mark("two")
      marks = a.model.marks
    }
    #expect(marks.map(\.name) == ["one", "two"])
    #expect(marks[0].rects["box"] == CGRect(x: 100, y: 50, width: 40, height: 20))
    #expect(abs(marks[1].time - marks[0].time - 0.3) < 0.05)
  }

  @Test func enterArrivesFromPastTheNearestEdge() async throws {
    var samples: [CGPoint] = []
    var last = CGPoint.zero
    try await Harness.run(S(), width: 400, height: 400, cursor: true) { s, _ in
      Color.red.frame(width: 20, height: 20).target("edge").offset(x: 370, y: 200)
    } script: { a in
      let watch = Task { @MainActor in
        while !Task.isCancelled { samples.append(a.cursor.position); try await Task.sleep(for: .milliseconds(5)) }
      }
      try await a.enter("edge")
      watch.cancel()
      last = a.cursor.position
    }
    // The right edge is nearest: it starts past x = 400 and settles on the target.
    #expect(samples.first { $0 != .zero }.map { $0.x > 400 } == true)
    #expect(last == CGPoint(x: 380, y: 210))
  }

  @Test func eachRunStartsWithTheCursorAtRest() async throws {
    var starts: [CGPoint] = []
    let stage = Stage(width: 200, height: 100, initial: S(), play: .loop, cursor: StageCursor(at: .point(CGPoint(x: 150, y: 80)))) { a in
      starts.append(a.cursor.position)
      try a.place(.point(CGPoint(x: 5, y: 5)))
      try await a.wait(.milliseconds(60))
    } content: { s, _ in Self.scene(s) }
    let w = Host.show(stage)
    await Host.pause(400)
    w.isHidden = true
    #expect(starts.count >= 2)
    #expect(starts.allSatisfy { $0 == CGPoint(x: 150, y: 80) })
  }

  // A stage removed from the hierarchy cancels its run; puts after that
  // change nothing. (A hidden UIWindow is not removal: SwiftUI sends no
  // onDisappear for it, so a stage there keeps running.)
  @Test func cancelStopsTheScriptAndLaterPutsDoNothing() async throws {
    @MainActor final class Box: ObservableObject { @Published var on = true }
    struct Holder<V: View>: View { @ObservedObject var box: Box; let v: V
      var body: some View { VStack { if box.on { v } } }
    }
    var after: Int?
    var caught: (any Error)?
    let box = Box()
    let stage = Stage(width: 200, height: 100, initial: S(), play: .once) { a in
      do {
        try await a.wait(.seconds(10))
      } catch {
        caught = error
        a.put { $0.n = 99 }
        after = a.model.state.n
      }
    } content: { s, _ in Self.scene(s) }
    let w = Host.show(Holder(box: box, v: stage))
    defer { w.isHidden = true }
    await Host.pause(200)
    box.on = false
    await Host.pause(200)
    #expect(caught is CancellationError)
    #expect(after == 0)
  }
}
