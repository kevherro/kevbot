import SwiftUI
import Testing
import UIKit
@testable import StageshowKit

// Assertions from upstream references/kit.md, one test per rule, for the
// parts payout-flow and form-error use. Views are drawn in a real window
// and read back from pixels or measured sizes.

@MainActor
private func size(of v: some View, width: CGFloat = 400) async -> CGSize {
  var s = CGSize.zero
  let w = Host.show(v.fixedSize(horizontal: false, vertical: true).onGeometryChange(for: CGSize.self) { $0.size } action: { s = $0 }
    .frame(width: width).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).ignoresSafeArea())
  await Host.pause(150)
  w.isHidden = true
  return s
}

/// Shows `v` at the window's top left on white and returns a capture after `ms`.
@MainActor
private func shot(_ v: some View, after ms: Int = 200, then change: (() -> Void)? = nil, at later: [Int] = []) async -> [Pixels] {
  let w = Host.show(v.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(Color.white).ignoresSafeArea())
  defer { w.isHidden = true }
  await Host.pause(ms)
  let first = Host.capture(w)
  lastImages = [first]
  var out = [Pixels(first)]
  change?()
  var last = 0
  for t in later {
    await Host.pause(t - last)
    last = t
    let img = Host.capture(w)
    lastImages.append(img)
    out.append(Pixels(img))
  }
  return out
}

@MainActor var lastImages: [UIImage] = []

@MainActor final class Flag: ObservableObject { @Published var on = false; @Published var n = 0.0; @Published var text = "" }

private extension Pixels {
  func count(in r: CGRect, _ test: ((r: Int, g: Int, b: Int)) -> Bool) -> Int {
    var n = 0
    for y in Int(r.minY * scale)..<Int(r.maxY * scale) { for x in Int(r.minX * scale)..<Int(r.maxX * scale) where test(rgb(x, y)) { n += 1 } }
    return n
  }
  /// Fraction of pixels that differ between two captures in a region.
  func diff(_ o: Pixels, in r: CGRect) -> Double {
    var n = 0, d = 0
    for y in Int(r.minY * scale)..<Int(r.maxY * scale) {
      for x in Int(r.minX * scale)..<Int(r.maxX * scale) {
        n += 1
        let a = rgb(x, y), b = o.rgb(x, y)
        if abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b) > 30 { d += 1 }
      }
    }
    return Double(d) / Double(max(1, n))
  }
}

private func isGreen(_ p: (r: Int, g: Int, b: Int)) -> Bool { p.g > 150 && p.r < 120 && p.b < 140 }
private func isBlack(_ p: (r: Int, g: Int, b: Int)) -> Bool { p.r < 90 && p.g < 90 && p.b < 90 }

@MainActor
@Suite(.serialized)
struct BarTests {
  @Test func aLineThatFitsIsExactlyItsWidth() async {
    #expect(await size(of: HStack { Bar(w: 120, h: 6); Spacer() }).width == 400)
    var w: CGFloat = 0
    let win = Host.show(Bar(w: 120, h: 6).onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w = $0 })
    await Host.pause(150); win.isHidden = true
    #expect(w == 120)
  }

  @Test func aLineGivesWayInANarrowRowAndNeverRunsPast() async {
    var w: CGFloat = 0
    let win = Host.show(HStack(spacing: 0) { Bar(w: 120, h: 6).onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w = $0 }; Color.red.frame(width: 40) }.frame(width: 100))
    await Host.pause(150); win.isHidden = true
    #expect(w == 60)
  }

  @Test func anIconSlotKeepsItsSizeUnlessShrinkSaysSo() async {
    var slot: CGFloat = 0, shrunk: CGFloat = 0
    let win = Host.show(VStack {
      HStack(spacing: 0) { Bar(w: 18, h: 18).onGeometryChange(for: CGFloat.self) { $0.size.width } action: { slot = $0 }; Color.red.frame(width: 20) }.frame(width: 30)
      HStack(spacing: 0) { Bar(w: 18, h: 18, shrink: true).onGeometryChange(for: CGFloat.self) { $0.size.width } action: { shrunk = $0 }; Color.red.frame(width: 20) }.frame(width: 30)
    })
    await Host.pause(150); win.isHidden = true
    #expect(slot == 18)
    #expect(shrunk == 10)
  }
}

@MainActor
@Suite(.serialized)
struct SceneTextTests {
  func measure(_ fidelity: Fidelity, _ t: SceneText) async -> (w: CGFloat, isBar: Bool) {
    var w: CGFloat = 0
    let px = await shot(t.font(.system(size: 20)).foregroundStyle(.black).environment(\.stageFidelity, fidelity)
      .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { w = $0 })
    let ink = px[0].count(in: CGRect(x: 0, y: 0, width: 300, height: 40), isBlack)
    return (w, ink == 0)
  }

  @Test func realWordsAtStandardABarAtMinimal() async {
    let words = await measure(.standard, SceneText("Payouts", size: 20))
    let bar = await measure(.minimal, SceneText("Payouts", size: 20))
    #expect(!words.isBar)
    #expect(bar.isBar)
    #expect(bar.w == (7 * 20 * 0.52).rounded())
  }

  @Test func fillerIsWordsOnlyAtRealistic() async {
    #expect(await measure(.standard, SceneText("Filler line", filler: true, size: 20)).isBar)
    #expect(await measure(.realistic, SceneText("Filler line", filler: true, size: 20)).isBar == false)
  }

  @Test func oneLineUnlessWrap() async {
    let long = "a long sentence that will not fit in this narrow space at all"
    let one = await size(of: SceneText(long), width: 80)
    let wrapped = await size(of: SceneText(long, wrap: true), width: 80)
    #expect(wrapped.height > one.height * 2)
  }
}

@MainActor
@Suite(.serialized)
struct IconTests {
  @Test func everyNameDrawsAGlyphAtItsSize() async {
    var empty: [String] = []
    for name in IconName.allCases {
      for filled in [false, true] {
        let px = await shot(Icon(name, size: 24, filled: filled).foregroundStyle(.black).padding(8), after: 60)
        let tag = name.rawValue + (filled ? " filled" : "")
        if px[0].count(in: CGRect(x: 8, y: 8, width: 24, height: 24), isBlack) < 10 { empty.append(tag) }
        if px[0].count(in: CGRect(x: 34, y: 0, width: 20, height: 40), isBlack) > 0 { empty.append(tag + " (outside its box)") }
      }
    }
    print("MEASURE icon.empty \(empty)")
    #expect(empty.isEmpty)
  }

  @Test func filledIsSolid() async {
    let outline = await shot(Icon(.bolt, size: 32).foregroundStyle(.black), after: 60)[0].count(in: CGRect(x: 0, y: 0, width: 32, height: 32), isBlack)
    let solid = await shot(Icon(.bolt, size: 32, filled: true).foregroundStyle(.black), after: 60)[0].count(in: CGRect(x: 0, y: 0, width: 32, height: 32), isBlack)
    print("MEASURE icon.bolt outline=\(outline) solid=\(solid)")
    // SF Symbols' outline bolt is heavy already; the fill adds its interior.
    #expect(Double(solid) > Double(outline) * 1.15)
  }
}

@MainActor
@Suite(.serialized)
struct CheckTests {
  struct V: View { @ObservedObject var f: Flag; let pending: Bool
    var body: some View { Check(on: f.on, pending: pending, size: 40, arc: .black).padding(10) }
  }
  let disc = CGRect(x: 18, y: 18, width: 24, height: 24)

  @Test func pendingTurnsAnArcInsideTheRingWithNoDisc() async {
    let px = await shot(V(f: Flag(), pending: true), after: 300)[0]
    #expect(px.count(in: CGRect(x: 10, y: 10, width: 40, height: 40), isBlack) > 20)
    #expect(px.count(in: disc, isGreen) == 0)
  }

  @Test func onGrowsADiscThenDrawsTheTickAndNoSpinnerStays() async {
    let f = Flag()
    let px = await shot(V(f: f, pending: true), after: 300, then: { f.on = true }, at: [60, 700])
    // Early: the disc is growing from the center, the tick not drawn yet.
    #expect(px[1].count(in: disc, isGreen) < px[2].count(in: disc, isGreen))
    // Done: a solid disc, a white tick on it, and no dark arc anywhere.
    #expect(px[2].count(in: disc, isGreen) > 300)
    #expect(px[2].count(in: disc) { $0.r > 240 && $0.g > 240 && $0.b > 240 } > 20)
    #expect(px[2].count(in: CGRect(x: 10, y: 10, width: 40, height: 40), isBlack) == 0)
  }

  @Test func theTickFadesOutIntactRatherThanUndrawing() async {
    let f = Flag()
    f.on = true
    let px = await shot(V(f: f, pending: false), after: 700, then: { f.on = false }, at: [100])
    // Mid fade the tick's far end (its long stroke's tip) is still there.
    let tip = CGRect(x: 10 + 11.6 * 2.5 - 3, y: 10 + 5.6 * 2.5 - 3, width: 6, height: 6)
    #expect(px[1].count(in: tip) { $0.r > 200 && $0.g > 200 && $0.b > 200 && !($0.r > 250 && $0.g > 250 && $0.b > 250) } > 0 || px[1].count(in: tip, isGreen) > 0)
  }
}

@MainActor
@Suite(.serialized)
struct CountTests {
  struct V: View { @ObservedObject var f: Flag
    var body: some View { Count(f.n, duration: .milliseconds(600), format: { String(format: "%.0f", $0) }).font(.system(size: 40)).foregroundStyle(.black).padding(10) }
  }

  @Test func settlesOnTheFormattedValueLikePlainText() async {
    let f = Flag()
    f.n = 1240
    let count = await shot(V(f: f), after: 300, then: { f.n = 1250 }, at: [1200])[1]
    let plain = await shot(Text("1250").font(.system(size: 40)).monospacedDigit().foregroundStyle(.black).padding(10), after: 200)[0]
    let a = count.bounds(isBlack)!, b = plain.bounds(isBlack)!
    print("MEASURE count.inkBounds count=\(a) plain=\(b)")
    // Each digit is its own view, so each rounds to the 1/3pt pixel grid:
    // four digits may drift by up to about a point in all.
    #expect(abs(a.minX - b.minX) <= 0.5 && abs(a.maxX - b.maxX) <= 1 && abs(a.minY - b.minY) <= 0.5 && abs(a.maxY - b.maxY) <= 0.5)
  }

  @Test func onlyChangedDigitsMoveTheLastFirst() async {
    let f = Flag()
    f.n = 1199
    // 1199 -> 1200: three digits change; the thousands digit holds still.
    let px = await shot(V(f: f), after: 300, then: { f.n = 1200 }, at: [60, 1200])
    let digit = 23.0  // a 40pt tabular digit is about 23pt wide
    let first = CGRect(x: 10, y: 10, width: digit, height: 48)
    let last = CGRect(x: 10 + digit * 3, y: 10, width: digit, height: 48)
    let second = CGRect(x: 10 + digit, y: 10, width: digit, height: 48)
    #expect(px[1].diff(px[0], in: first) < 0.01)
    #expect(px[1].diff(px[0], in: last) > px[1].diff(px[0], in: second))
    #expect(px[2].diff(px[0], in: last) > 0.05)
  }

  @Test func aRisePassingNineCarriesOnThroughZero() {
    // From 9 rising to 1: the strip moves +2 (9, 0, 1), never back 8 places.
    #expect(Count.roll(from: [9], to: [1], at: [19], up: true, instant: false) == [21])
    #expect(Count.roll(from: [1], to: [9], at: [11], up: false, instant: false) == [9])
    #expect(Count.roll(from: [3, 4], to: [3, 5], at: [13, 14], up: true, instant: false) == [13, 15])
    #expect(Count.roll(from: [9], to: [1], at: [19], up: true, instant: true) == [11])
  }

  @Test func aUnitGetsABoxOfItsOwn() {
    #expect(Count.unit("21°").unit == "°")
    #expect(Count.unit("12 min") == ("12", true, "min"))
    #expect(Count.unit("$1,200.50").unit == "")
  }

  @Test func insideASnapItJumps() async throws {
    var mids: [Bool] = []
    struct S: Equatable { var n = 1240.0 }
    try await Harness.run(S(), width: 300, height: 100) { s, _ in
      Count(s.n, duration: .milliseconds(600), format: { String(format: "%.0f", $0) }).font(.system(size: 40)).foregroundStyle(.black).target("c")
    } script: { a in
      try await a.wait(.milliseconds(100))
      let w = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first!.windows.first { $0.windowLevel == .alert + 1 && !$0.isHidden }!
      let before = Pixels(Host.capture(w))
      try await a.snap { $0.n = 1250 }
      let after = Pixels(Host.capture(w))
      try await a.wait(.milliseconds(700))
      let settled = Pixels(Host.capture(w))
      mids.append(after.diff(settled, in: CGRect(x: 0, y: 0, width: 150, height: 60)) < 0.01)
      mids.append(after.diff(before, in: CGRect(x: 0, y: 0, width: 150, height: 60)) > 0.01)
    }
    #expect(mids == [true, true])
  }
}

@MainActor
@Suite(.serialized)
struct RollTests {
  @Test func onlyTheChangedPartRollsAndWordsMoveWhole() {
    let num = Roll.split("$0.01 per 1,000", "$0.0098 per 1,000")
    #expect(num.head == 4 && num.tail == 10 && num.numeric)
    let words = Roll.split("Checking calendars", "Everyone can make it")
    #expect(words.head == 0 && words.tail == 0 && !words.numeric)
    let label = Roll.split("Pending", "Paid")
    #expect(label.head == 0 && label.tail == 0)
    let tail = Roll.split("3 new messages", "4 new messages")
    #expect(tail.tail == 13 && tail.head == 0)
  }

  struct V: View { @ObservedObject var f: Flag; let delay: Duration
    var body: some View { Roll(f.text, delay: delay).font(.system(size: 30)).foregroundStyle(.black).padding(10) }
  }

  @Test func theSharedEndsHoldStill() async {
    let f = Flag()
    f.text = "Total $120 due"
    let px = await shot(V(f: f, delay: .zero), after: 300, then: { f.text = "Total $180 due" }, at: [150])
    // "Total $1" holds; the changing digit moves.
    #expect(px[1].diff(px[0], in: CGRect(x: 10, y: 10, width: 95, height: 36)) < 0.01)
    #expect(px[1].diff(px[0], in: CGRect(x: 108, y: 10, width: 18, height: 36)) > 0.05)
  }

  @Test func delayHoldsTheOldText() async {
    let f = Flag()
    f.text = "Total $120"
    let px = await shot(V(f: f, delay: .milliseconds(400)), after: 300, then: { f.text = "Total $180" }, at: [250, 1100])
    let region = CGRect(x: 0, y: 0, width: 200, height: 56)
    #expect(px[1].diff(px[0], in: region) < 0.002)
    #expect(px[2].diff(px[0], in: region) > 0.002)
  }
}

@MainActor
@Suite(.serialized)
struct SwapTests {
  struct V: View { @ObservedObject var f: Flag
    var body: some View {
      HStack(spacing: 0) {
        Swap(id: f.on) { Text(f.on ? "Sent" : "Sending a long label") }
        Color.red.frame(width: 4, height: 30)
      }
      .font(.system(size: 24))
      .padding(10)
    }
  }

  // The red marker after the swap rides the box's edge.
  @Test func theBoxEasesBetweenSizesAndLandsOnTheNew() async {
    let f = Flag()
    let px = await shot(V(f: f), after: 300, then: { f.on = true }, at: [450, 1300])
    let x = px.map { $0.bounds(Pixels.isRed)?.minX ?? -1 }
    print("MEASURE swap.markerX \(x)")
    #expect(x[1] < x[0] - 1 && x[1] > x[2] + 1)
    #expect(x[2] < x[0])
  }
}

@MainActor
@Suite(.serialized)
struct ConnectorTests {
  struct V: View { @ObservedObject var f: Flag
    var body: some View {
      Connector(from: CGPoint(x: 20, y: 20), to: CGPoint(x: 220, y: 20), route: .straight, show: f.on, dots: .end)
        .environment(\.stageLook, StageLook.light.accent(.black))
        .frame(width: 300, height: 60)
    }
  }
  let start = CGRect(x: 20, y: 17, width: 20, height: 6)
  let end = CGRect(x: 200, y: 17, width: 16, height: 6)
  let dot = CGRect(x: 216, y: 16, width: 8, height: 8)

  @Test func drawsOnFromTheStartThenTheDotArrives() async {
    let f = Flag()
    let px = await shot(V(f: f), after: 200, then: { f.on = true }, at: [500, 1500])
    #expect(px[1].count(in: start, isBlack) > 0)
    #expect(px[1].count(in: end, isBlack) == 0)
    #expect(px[1].count(in: dot, isBlack) == 0)
    #expect(px[2].count(in: end, isBlack) > 0)
    #expect(px[2].count(in: dot, isBlack) > 0)
  }

  @Test func fadesOffIntact() async {
    let f = Flag()
    f.on = true
    let px = await shot(V(f: f), after: 1400, then: { f.on = false }, at: [100, 600])
    // Mid fade: both ends still drawn, only lighter.
    #expect(px[1].count(in: end) { $0.r < 230 } > 0)
    #expect(px[1].count(in: start) { $0.r < 230 } > 0)
    #expect(px[2].count(in: CGRect(x: 0, y: 0, width: 300, height: 60)) { $0.r < 230 } == 0)
  }
}

@MainActor
@Suite(.serialized)
struct FieldTests {
  struct V: View { @ObservedObject var f: Flag; var status: Field.Status? = nil; var password = false
    var body: some View {
      Field(label: "Work email", value: f.text, placeholder: "name@company.com", focused: f.on, password: password, status: status)
        .environment(\.stageLook, StageLook.light.accent(Color(red: 0, green: 0, blue: 1)))
        .frame(width: 280).padding(10)
    }
  }
  let box = CGRect(x: 10, y: 29, width: 280, height: 34)
  func isBlue(_ p: (r: Int, g: Int, b: Int)) -> Bool { p.b > 200 && p.r < 120 && p.g < 120 }
  func isRedRing(_ p: (r: Int, g: Int, b: Int)) -> Bool { p.r > 200 && p.g < 120 && p.b < 120 }

  @Test func focusRingNeverMovesTheText() async {
    let f = Flag()
    f.text = "maya"
    let px = await shot(V(f: f), after: 200, then: { f.on = true }, at: [400])
    let text = CGRect(x: 21, y: 35, width: 60, height: 22)
    #expect(px[0].bounds(isBlack) != nil)
    #expect(px[0].count(in: box, isBlue) == 0)
    #expect(px[1].count(in: box.insetBy(dx: -3, dy: -3), isBlue) > 100)
    let a = px[0].count(in: text, isBlack), b = px[1].count(in: text, isBlack)
    #expect(abs(a - b) <= 2)
  }

  @Test func placeholderLeavesOnTheFirstCharacter() async {
    let f = Flag()
    let px = await shot(V(f: f), after: 200, then: { f.text = "m" }, at: [17])
    let tail = CGRect(x: 60, y: 35, width: 120, height: 22)
    #expect(px[0].count(in: tail) { $0.r < 200 } > 20)
    #expect(px[1].count(in: tail) { $0.r < 200 } == 0)
  }

  @Test func caretIsSolidWhileTypingAndBlinksAtRest() async {
    let f = Flag()
    f.on = true
    let caret = CGRect(x: 18, y: 37, width: 180, height: 18)
    let w = Host.show(V(f: f).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(Color.white).ignoresSafeArea())
    defer { w.isHidden = true }
    var typing: [Int] = [], resting: [Int] = []
    for i in 0..<8 { f.text = String(repeating: "m", count: i + 1); await Host.pause(60); typing.append(Pixels(Host.capture(w)).count(in: caret, isBlue)) }
    await Host.pause(800)
    for _ in 0..<12 { await Host.pause(90); resting.append(Pixels(Host.capture(w)).count(in: caret, isBlue)) }
    print("MEASURE field.caret typing=\(typing) resting=\(resting)")
    #expect(typing.allSatisfy { $0 > 0 })
    #expect(resting.contains(0) && resting.contains { $0 > 0 })
  }

  @Test func errorTurnsTheRingAndValidDrawsACheck() async {
    let f = Flag()
    f.text = "maya@northwind"
    let err = await shot(V(f: f, status: .error), after: 400)[0]
    #expect(err.count(in: box.insetBy(dx: -3, dy: -3), isRedRing) > 100)
    f.text = "maya@northwind.co"
    let ok = await shot(V(f: f, status: .valid), after: 600)[0]
    #expect(ok.count(in: CGRect(x: 262, y: 39, width: 16, height: 16), isGreen) > 10)
  }

  @Test func passwordShowsDots() async {
    let f = Flag()
    f.text = "northwind-2026"
    let px = await shot(V(f: f, password: true), after: 200)[0]
    let plain = await shot(V(f: f), after: 200)[0]
    #expect(px.bounds(isBlack) != plain.bounds(isBlack))
  }
}

@MainActor
@Suite(.serialized)
struct StatesTests {
  struct V: View { @ObservedObject var f: Flag; let report: (CGSize) -> Void
    var body: some View {
      HStack(spacing: 0) {
        States(value: f.on ? "long" : "short", align: .leading, states: [
          "short": Text("Hi"),
          "long": Text("A much longer state"),
        ])
        .onGeometryChange(for: CGSize.self) { $0.size } action: { report($0) }
        Color.red.frame(width: 4, height: 20)
      }
      .font(.system(size: 20)).foregroundStyle(.black).padding(10)
    }
  }

  @Test func theBoxHoldsTheLargestStateSoNothingAroundItMoves() async {
    let f = Flag()
    var sizes: [CGSize] = []
    let px = await shot(V(f: f) { sizes.append($0) }, after: 300, then: { f.on = true }, at: [100, 600])
    let x = px.map { $0.bounds(Pixels.isRed)?.minX ?? -1 }
    #expect(Set(sizes).count == 1)
    #expect(x[0] == x[1] && x[1] == x[2])
  }

  @Test func theOutgoingStateIsMostlyGoneBeforeTheIncomingArrives() async {
    let f = Flag()
    let px = await shot(V(f: f) { _ in }, after: 300, then: { f.on = true }, at: [80, 600])
    let shortZone = CGRect(x: 10, y: 10, width: 22, height: 26)
    let longOnly = CGRect(x: 40, y: 10, width: 120, height: 26)
    // At 80ms the short label has faded most of the way; the long one has
    // barely started (it waits 70ms).
    #expect(px[1].count(in: shortZone, isBlack) < px[0].count(in: shortZone, isBlack))
    #expect(px[1].count(in: longOnly, isBlack) < px[2].count(in: longOnly, isBlack) / 2)
  }
}
