import SwiftUI
import Testing
import UIKit
@testable import StageshowKit

// One test per behavior of upstream stage.tsx a host or script can
// observe: fit, layout, poster, playback, visibility, the fixed picture.

@MainActor
@Suite(.serialized)
struct StageTests {
  struct S: Equatable { var step = 0 }

  @MainActor final class Log { var lines: [String] = []; var runs = 0 }

  static func card(_ s: S, _ layout: StageLayout) -> some View {
    Text("step \(s.step) \(layout.rawValue)").font(.system(size: 20)).target("label")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  func show(_ v: some View, width: CGFloat) -> UIWindow {
    Host.show(v.frame(width: width).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).ignoresSafeArea())
  }

  func height(of w: UIWindow, _ v: CGSize) -> CGSize { w.rootViewController!.view.subviews.first?.bounds.size ?? .zero }

  @Test func scalesDownToFitItsContainerAndKeepsDesignCoordinates() async throws {
    var rect: CGRect?
    var size: CGSize?
    let stage = Stage(width: 400, height: 200, initial: S(), play: .once) { a in
      try await a.wait(.milliseconds(100))
      rect = a.rect("label")
    } content: { s, l in Self.card(s, l) }
    let w = show(stage.onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }, width: 200)
    defer { w.isHidden = true }
    await Host.pause(400)
    print("MEASURE stage.fit size=\(String(describing: size)) rect=\(String(describing: rect))")
    #expect(size == CGSize(width: 200, height: 100))
    #expect(rect.map { abs($0.midX - 200) < 0.5 } == true)
  }

  @Test func neverGrowsPastItsDesignSize() async {
    var size: CGSize?
    let stage = Stage(width: 300, height: 100, initial: S()) { s, l in Self.card(s, l) }
    let w = show(stage.onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }, width: 402)
    defer { w.isHidden = true }
    await Host.pause(300)
    #expect(size?.height == 100)
  }

  @Test func compactDesignBelowItsWidth() async throws {
    let log = Log()
    func make(_ width: CGFloat) -> some View {
      Stage(width: 600, height: 300, compact: CompactDesign(below: 500, width: 358, height: 400), initial: S(), play: .once) { a in
        log.lines.append("\(width) \(a.layout.rawValue)")
      } content: { s, l in Self.card(s, l) }
    }
    let narrow = show(make(390), width: 390)
    await Host.pause(300)
    narrow.isHidden = true
    let wide = show(make(600), width: 600)
    await Host.pause(300)
    wide.isHidden = true
    #expect(log.lines == ["390.0 compact", "600.0 wide"])
  }

  @Test func posterShowsWithoutAScriptOrUnderReduceMotion() async {
    let log = Log()
    func probe(_ s: S, _ l: StageLayout) -> some View {
      let _ = log.lines.append("step \(s.step)")
      return Self.card(s, l)
    }
    let noScript = show(Stage(width: 200, height: 100, initial: S(), poster: S(step: 6), content: probe), width: 200)
    await Host.pause(200)
    noScript.isHidden = true
    #expect(log.lines.last == "step 6")
    log.lines = []
    var ran = false
    let reduced = show(Stage(width: 200, height: 100, initial: S(), poster: S(step: 7), script: { _ in ran = true }, content: probe)
      .environment(\.stageReduceMotionOverride, true), width: 200)
    await Host.pause(300)
    reduced.isHidden = true
    #expect(log.lines.last == "step 7")
    #expect(!ran)
  }

  @Test func loopStartsEachRunFromInitial() async {
    let log = Log()
    let stage = Stage(width: 200, height: 100, initial: S(), play: .loop) { a in
      log.lines.append("start \(a.model.state.step)")
      try await a.set { $0.step = 5 }
      try await a.wait(.milliseconds(50))
    } content: { s, l in Self.card(s, l) }
    let w = show(stage, width: 200)
    await Host.pause(500)
    w.isHidden = true
    #expect(log.lines.count >= 3)
    #expect(log.lines.allSatisfy { $0 == "start 0" })
  }

  @Test func onceHoldsTheEndAndDoesNotReplayOnReturn() async {
    let log = Log()
    var shown = true
    struct Holder<V: View>: View { @State var on = true; let v: V; let toggle: (Binding<Bool>) -> Void
      var body: some View { VStack { if on { v } }.onAppear { toggle($on) } }
    }
    var flip: Binding<Bool>?
    let stage = Stage(width: 200, height: 100, initial: S(), play: .once) { a in
      log.runs += 1
      try await a.set { $0.step = 3 }
    } content: { s, l in let _ = log.lines.append("\(s.step)"); Self.card(s, l) }
    let w = show(Holder(v: stage, toggle: { flip = $0 }), width: 200)
    await Host.pause(300)
    // Leave the screen and come back: the same view, scrolled away and back.
    let host = w.rootViewController!.view!
    host.isHidden = true
    await Host.pause(100)
    host.isHidden = false
    await Host.pause(300)
    w.isHidden = true
    _ = (shown, flip)
    shown = false
    #expect(log.runs == 1)
    #expect(log.lines.last == "3")
  }

  @Test func scrollingOffStopsAndResetsAndScrollingBackRestarts() async {
    let log = Log()
    @MainActor final class Pos: ObservableObject { @Published var p = ScrollPosition(y: 0) }
    struct V<St: View>: View { @ObservedObject var pos: Pos; let stage: St
      var body: some View {
        ScrollView { VStack(spacing: 0) { stage; Color.clear.frame(height: 4000) } }.scrollPosition($pos.p)
      }
    }
    let pos = Pos()
    let stage = Stage(width: 200, height: 100, initial: S(), play: .once) { a in
      log.runs += 1
      try await a.set { $0.step = 1 }
      do { try await a.wait(.seconds(30)) } catch { log.lines.append("canceled"); throw error }
    } content: { s, l in let _ = log.lines.append("draw \(s.step)"); Self.card(s, l) }
    let w = show(V(pos: pos, stage: stage), width: 300)
    defer { w.isHidden = true }
    await Host.pause(300)
    pos.p = ScrollPosition(y: 2000)
    await Host.pause(300)
    let afterOff = log.lines
    pos.p = ScrollPosition(y: 0)
    await Host.pause(300)
    print("MEASURE stage.scroll afterOff=\(afterOff.suffix(4)) runs=\(log.runs)")
    #expect(afterOff.contains("canceled"))
    #expect(afterOff.suffix(2).contains("draw 0"))
    #expect(log.runs == 2)
  }

  @Test func backgroundStopsAndForegroundRestarts() async {
    let log = Log()
    let stage = Stage(width: 200, height: 100, initial: S(), play: .once) { a in
      log.runs += 1
      do { try await a.wait(.seconds(30)) } catch { log.lines.append("canceled"); throw error }
    } content: { s, l in Self.card(s, l) }
    let w = show(stage, width: 200)
    defer { w.isHidden = true }
    await Host.pause(200)
    NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: UIApplication.shared)
    await Host.pause(200)
    #expect(log.lines == ["canceled"])
    NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: UIApplication.shared)
    await Host.pause(200)
    #expect(log.runs == 2)
  }

  @Test func dynamicTypeDoesNotChangeTheScene() async throws {
    var rects: [CGRect] = []
    for size in [DynamicTypeSize.xSmall, .large, .accessibility5] {
      let stage = Stage(width: 300, height: 100, initial: S(), play: .once) { a in
        try await a.wait(.milliseconds(50))
        rects.append(a.rect("t") ?? .zero)
      } content: { _, _ in Text("Fixed picture").font(.body).target("t") }
      let w = show(stage.dynamicTypeSize(size), width: 300)
      await Host.pause(300)
      w.isHidden = true
    }
    #expect(rects.count == 3)
    #expect(Set(rects).count == 1)
  }

  @Test func severalStagesRunIndependently() async {
    let log = Log()
    let make = { (name: String, ms: Int) in
      Stage(width: 150, height: 80, initial: S(), play: .once) { a in
        try await a.wait(.milliseconds(ms))
        a.mark(name)
        log.lines.append("\(name) \(a.model.marks.map(\.name))")
      } content: { s, l in Self.card(s, l) }
    }
    let w = Host.show(VStack { make("a", 300); make("b", 100); make("c", 200) })
    defer { w.isHidden = true }
    await Host.pause(600)
    #expect(log.lines == ["b [\"b\"]", "c [\"c\"]", "a [\"a\"]"])
  }
}
