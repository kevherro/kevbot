import SwiftUI
import Testing
import UIKit
@testable import StageshowKit

// The spike's results, reproduced in Swift 6 language mode on the iOS 27
// simulator. Each test names the SwiftUI behavior the kit relies on, so a
// point release that changes it fails here by name.

struct Slider: View {
  let on: Bool
  var body: some View {
    Color.red.frame(width: 40, height: 40).offset(x: on ? 200 : 0)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
  }
}

@MainActor
final class Toggle: ObservableObject { @Published var on = false }

struct ToggleSlider: View {
  @ObservedObject var t: Toggle
  var body: some View { Slider(on: t.on).background(Color.white) }
}

@MainActor
private func redX(_ image: UIImage) -> CGFloat? { Pixels(image).bounds(Pixels.isRed)?.minX }

@MainActor
@Suite(.serialized)
struct CaptureSpike {
  // Animates the red square 0 -> 200pt over 1s and returns what `grab`
  // sees at 0.5s.
  func midway(_ grab: (UIWindow) -> UIImage) async -> CGFloat? {
    let t = Toggle()
    let w = Host.show(ToggleSlider(t: t).ignoresSafeArea())
    defer { w.isHidden = true }
    await Host.pause(300)
    withAnimation(.linear(duration: 1)) { t.on = true }
    await Host.pause(500)
    return redX(grab(w))
  }

  func render(_ w: UIWindow, presentation: Bool) -> UIImage {
    let f = UIGraphicsImageRendererFormat()
    f.scale = w.screen.scale
    return UIGraphicsImageRenderer(bounds: w.bounds, format: f).image { ctx in
      let layer = presentation ? (w.layer.presentation() ?? w.layer) : w.layer
      layer.render(in: ctx.cgContext)
    }
  }

  @Test func drawHierarchyCapturesInFlight() async {
    let x = await midway { Host.capture($0) }
    print("MEASURE capture.drawHierarchy x=\(x ?? -1)")
    #expect(x.map { $0 > 40 && $0 < 160 } == true)
  }

  @Test func presentationLayerCapturesInFlight() async {
    let x = await midway { render($0, presentation: true) }
    print("MEASURE capture.presentation x=\(x ?? -1)")
    #expect(x.map { $0 > 40 && $0 < 160 } == true)
  }

  @Test func plainLayerRenderStaysAtStart() async {
    let x = await midway { render($0, presentation: false) }
    print("MEASURE capture.layerRender x=\(x ?? -1)")
    #expect(x.map { $0 < 5 } == true)
  }

  @Test func imageRendererDrawsFinalValuesOnly() async {
    let t = Toggle()
    withAnimation(.linear(duration: 1)) { t.on = true }
    let r = ImageRenderer(content: ToggleSlider(t: t).frame(width: 400, height: 100))
    r.scale = 2
    let x = redX(r.uiImage!)
    print("MEASURE capture.imageRenderer x=\(x ?? -1)")
    #expect(x == 200)
  }
}

// Records every value SwiftUI computes for an animated offset, with the
// time it computed it, so the comparison is per frame, not per capture.
nonisolated struct SpringProbe: ViewModifier, Animatable {
  var x: Double
  let log: FrameLog
  var animatableData: Double {
    get { x }
    set { x = newValue; MainActor.assumeIsolated { log.frames.append((CACurrentMediaTime(), newValue)) } }
  }
  func body(content: Content) -> some View { content.offset(x: x) }
}

@MainActor final class FrameLog { var frames: [(Double, Double)] = [] }

struct SpringView: View {
  @ObservedObject var t: Toggle
  let log: FrameLog
  var body: some View {
    Color.red.frame(width: 40, height: 40).modifier(SpringProbe(x: t.on ? 200 : 0, log: log))
  }
}


@MainActor
@Suite(.serialized)
struct CurveSpike {
  @Test func springValueMatchesWhatSwiftUIDraws() async {
    let spring = Spring(duration: 0.6, bounce: 0.3)
    let t = Toggle(), log = FrameLog()
    let w = Host.show(SpringView(t: t, log: log))
    defer { w.isHidden = true }
    await Host.pause(300)
    log.frames = []
    withAnimation(.spring(spring)) { t.on = true }
    await Host.pause(1200)
    let frames = log.frames
    // SwiftUI starts the clock at its next frame, not at withAnimation:
    // fit that one start time, then compare every frame.
    var best = (start: 0.0, worst: Double.infinity)
    let first = frames.first?.0 ?? 0
    for k in -40...40 {
      let start = first + Double(k) / 1000
      let worst = frames.map { abs($0.1 - spring.value(target: 200.0, time: max(0, $0.0 - start))) }.max() ?? .infinity
      if worst < best.worst { best = (start, worst) }
    }
    print("MEASURE curve.spring frames=\(frames.count) worst=\(String(format: "%.2f", best.worst))pt startOffset=\(String(format: "%.1f", (best.start - first) * 1000))ms")
    #expect(frames.count > 30)
    // The spike reported about 1pt; ten runs here measured 1.6 to 2.0pt
    // worst-case after fitting the start (see verification.md).
    #expect(best.worst < 2.5)
  }

  @Test func keyframeTimelineEvaluatesAtAnyTime() {
    let timeline = KeyframeTimeline(initialValue: 0.0) {
      LinearKeyframe(100.0, duration: 1)
      LinearKeyframe(300.0, duration: 1)
    }
    #expect(abs(timeline.value(time: 0.25) - 25) < 1e-9)
    #expect(abs(timeline.value(time: 1.5) - 200) < 1e-9)
    #expect(abs(timeline.duration - 2) < 1e-9)
  }

  @Test func unitCurveMatchesCSSBezier() {
    // An independent cubic-bezier solver (bisection on x), the CSS way.
    func css(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double, _ t: Double) -> Double {
      func bx(_ u: Double) -> Double { 3 * (1 - u) * (1 - u) * u * x1 + 3 * (1 - u) * u * u * x2 + u * u * u }
      func by(_ u: Double) -> Double { 3 * (1 - u) * (1 - u) * u * y1 + 3 * (1 - u) * u * u * y2 + u * u * u }
      var lo = 0.0, hi = 1.0
      for _ in 0..<60 { let m = (lo + hi) / 2; if bx(m) < t { lo = m } else { hi = m } }
      return by((lo + hi) / 2)
    }
    var worst = 0.0
    for t in stride(from: 0.0, through: 1.0, by: 0.05) {
      worst = max(worst, abs(Ease.house(t) - css(0.65, 0, 0.1, 1, t)))
      worst = max(worst, abs(Ease.enter(t) - css(0.1, 0.8, 0.3, 0.95, t)))
    }
    print("MEASURE curve.unitCurve worst=\(worst)")
    #expect(worst < 1e-3)
  }
}

// The suite can fail: with BENJIFY_DELIBERATE_FAILURE set, this claims
// ImageRenderer draws an animation mid-flight, which the spike disproved.
@MainActor
@Test(.enabled(if: ProcessInfo.processInfo.environment["BENJIFY_DELIBERATE_FAILURE"] != nil))
func deliberateFailureImageRendererInFlight() {
  let t = Toggle()
  withAnimation(.linear(duration: 1)) { t.on = true }
  let r = ImageRenderer(content: ToggleSlider(t: t).frame(width: 400, height: 100))
  let x = Pixels(r.uiImage!).bounds(Pixels.isRed)?.minX ?? -1
  #expect(x > 40 && x < 160, "ImageRenderer drew x=\(x): final value, not in flight")
}
