import StageshowKit
import SwiftUI

// Upstream: examples/payout-flow, at its compact (phone column) design,
// 358 x 610. A cursorless payout story played once as it scrolls into
// view. Things reveal, then move to make room for what comes next; groups
// stagger; a line ties the new card to the row it came from; the payoff is
// annotated. Long arrivals and overlapping beats.

struct PayoutFlow: View {
  struct S: Equatable {
    var step = 0
    var sent = false
  }

  var accessibilityLabel: String? = nil

  static let rows: [(amount: String, w: CGFloat)] = [("$12,400.00", 54), ("$8,915.20", 46)]

  static func script(_ a: Act<S>) async throws {
    try await a.wait(.milliseconds(300))
    a.mark("reveal")
    a.put { $0.step = 1 }  // the balance rises in and counts up
    try await a.wait(.milliseconds(700))
    a.put { $0.step = 2 }  // payout rows stagger in under it
    try await a.wait(.milliseconds(1500))
    a.mark("move")
    a.put { $0.step = 3 }  // the payout card arrives
    try await a.wait(.milliseconds(1300))
    a.put { $0.step = 4 }  // the line draws from the row to the card
    try await a.wait(.milliseconds(1100))
    a.mark("send")
    a.put { $0.step = 5 }  // sending
    try await a.wait(.milliseconds(1300))
    a.put { $0.sent = true }
    try await a.wait(.milliseconds(500))
    a.put { $0.step = 6 }  // the annotation lands
  }

  var body: some View {
    Stage(width: 358, height: 610, initial: S(), poster: S(step: 6, sent: true), play: .once,
          accent: Color(hex: 0x635BFF), accessibilityLabel: accessibilityLabel, script: Self.script) { s, _ in
      PayoutScene(s: s)
    } overlay: { s, rects, _ in
      if let row = rects["row-0"], let card = rects["instant"] {
        Connector(from: CGPoint(x: row.minX - 6, y: row.midY), to: CGPoint(x: card.minX, y: card.minY + 24), route: .v, show: s.step >= 4)
        PayoutNote(on: s.step >= 6)
          .offset(x: card.minX, y: card.maxY + 16)
      }
    }
  }
}

// The travel curve this story uses, not a universal preset.
private let spEase = Ease.bezier(0.45, 0, 0.1, 1)
private let arrive = Ease.bezier(0.25, 0.8, 0.25, 1)

// A CSS line box: `size` text in a line `lineHeight` times as tall.
private extension View {
  func line(_ size: CGFloat, _ weight: Font.Weight = .regular, lineHeight: CGFloat = 1.4) -> some View {
    font(.system(size: size, weight: weight)).frame(height: size * lineHeight)
  }
}

private struct PayoutScene: View {
  let s: PayoutFlow.S
  @Environment(\.stageLook) private var look

  var body: some View {
    ZStack(alignment: .topLeading) {
      look.isDark ? Color(hex: 0x111318) : Color(hex: 0xF6F8FB)
      // A soft accent wash from the top right corner.
      EllipticalGradient(colors: [look.accent.opacity(0.16), .clear], center: .center, startRadiusFraction: 0, endRadiusFraction: 0.35)
        .frame(width: 358, height: 732)
        .position(x: 358, y: 0)
      Balance(s: s)
      InstantCard(s: s)
    }
    .font(.system(size: 12))
    .foregroundStyle(look.textStrong)
    .frame(width: 358, height: 610, alignment: .topLeading)
    .clipShape(RoundedRectangle(cornerRadius: 14))
  }
}

private struct Balance: View {
  let s: PayoutFlow.S
  @Environment(\.stageLook) private var look

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Available balance").line(12).foregroundStyle(look.text)
      Count(s.step >= 1 ? 84210.5 : 0, duration: .milliseconds(1400), format: money)
        .font(.system(size: 26, weight: .semibold))
        .tracking(-0.52)
        .frame(height: 36.4)
        .padding(.vertical, 2)
      Bar(w: 120, h: 5, tone: 2)
      HStack {
        Text("Payouts").line(12, .semibold)
        Spacer()
        Bar(w: 40, h: 5, tone: 2)
      }
      .padding(.bottom, 7)  // 6 of padding and the 1pt rule under it
      .overlay(alignment: .bottom) { look.line.frame(height: 1) }
      .padding(.top, 14)
      ForEach(Array(PayoutFlow.rows.enumerated()), id: \.offset) { i, r in
        PayoutRow(i: i, amount: r.amount, w: r.w, sent: s.sent)
          .target("row-\(i)")
          .opacity(s.step >= 2 ? 1 : 0)
          .offset(y: s.step >= 2 ? 0 : 10)
          .animation(.easeInOut(duration: 0.7).delay(s.step >= 2 ? Double(i) * 0.09 : 0), value: s.step >= 2)
      }
    }
    .padding(.horizontal, 22)
    .padding(.top, 22)
    .frame(width: 326, height: 640, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 12).fill(look.surface).stageShadow(.hero))
    .target("balance")
    .opacity(s.step >= 1 ? 1 : 0)
    .animation(.easeInOut(duration: 0.9), value: s.step >= 1)
    .offset(y: s.step >= 1 ? 0 : 24)
    .animation(spEase.animation(1.2), value: s.step >= 1)
    .offset(x: 16, y: 24)
  }
}

private struct PayoutRow: View {
  let i: Int, amount: String, w: CGFloat, sent: Bool
  @Environment(\.stageLook) private var look

  var body: some View {
    HStack(spacing: 10) {
      Bank(size: 22, r: 6)
      Bar(w: w, h: 5, tone: 3)
      Spacer(minLength: 0)
      Text(amount).monospacedDigit()
      // The payout's own row settles when it sends, closing the loop.
      Group {
        if i == 0 { Roll(sent ? "Paid" : "Pending", variant: .fade) } else { Text("Paid") }
      }
      .font(.system(size: 10.5, weight: .medium))
      .padding(.horizontal, 7).padding(.vertical, 2)
      .background(RoundedRectangle(cornerRadius: 6).fill(look.successSoft))
      .foregroundStyle(look.successText)
    }
    .frame(height: 37)
    .overlay(alignment: .bottom) { look.lineFaint.frame(height: 1).offset(y: 1) }
    .frame(height: 38, alignment: .top)
  }
}

private struct Bank: View {
  let size: CGFloat, r: CGFloat
  @Environment(\.stageLook) private var look
  var body: some View {
    RoundedRectangle(cornerRadius: r).fill(look.ink(1))
      .overlay(RoundedRectangle(cornerRadius: r).strokeBorder(look.line, lineWidth: 1))
      .frame(width: size, height: size)
  }
}

private struct InstantCard: View {
  let s: PayoutFlow.S
  @Environment(\.stageLook) private var look

  var body: some View {
    let on = s.step >= 3
    VStack(alignment: .leading, spacing: 16) {
      HStack(spacing: 10) {
        Icon(.bolt, size: 14, filled: true)
          .foregroundStyle(look.accent)
          .frame(width: 28, height: 28)
          .background(RoundedRectangle(cornerRadius: 8).fill(look.accentSoft))
        Text("Instant payout").line(12, .semibold)
      }
      .modifier(Stagger(i: 0, on: on))
      Text("$12,400.00").font(.system(size: 24, weight: .semibold)).tracking(-0.48).frame(height: 33.6)
        .modifier(Stagger(i: 1, on: on))
      VStack(spacing: 0) {
        Field(label: "To") {
          HStack(spacing: 8) { Bank(size: 18, r: 5); Text("Chase ···· 4821") }
        }
        Field(label: "Fee") { Text("$124.00") }
      }
      .modifier(Stagger(i: 2, on: on))
      PayButton(step: s.step, sent: s.sent)
        .target("button")
        .padding(.top, 2)
        .modifier(Stagger(i: 3, on: on))
    }
    .padding(20)
    .frame(width: 302, alignment: .topLeading)
    .background(RoundedRectangle(cornerRadius: 12).fill(look.raised).stageShadow(.satellite))
    .target("instant")
    .opacity(on ? 1 : 0)
    .animation(.easeInOut(duration: 0.8).delay(0.2), value: on)
    .offset(x: on ? 0 : 32)
    .animation((on ? arrive : spEase).animation(1.1).delay(0.2), value: on)
    .offset(x: 40, y: 302)
  }

  // Its contents follow it in, 70ms apart.
  struct Stagger: ViewModifier {
    let i: Int, on: Bool
    func body(content: Content) -> some View {
      content
        .opacity(on ? 1 : 0)
        .animation(.easeInOut(duration: 0.6).delay(0.45 + Double(i) * 0.07), value: on)
        .offset(y: on ? 0 : 8)
        .animation((on ? arrive : spEase).animation(0.9).delay(0.45 + Double(i) * 0.07), value: on)
    }
  }

  struct Field<V: View>: View {
    let label: String
    @ViewBuilder let value: V
    @Environment(\.stageLook) private var look
    var body: some View {
      HStack {
        Text(label).foregroundStyle(look.text)
        Spacer()
        value
      }
      .frame(height: 36)
      .overlay(alignment: .top) { look.lineFaint.frame(height: 1) }
    }
  }
}

private struct PayButton: View {
  let step: Int, sent: Bool
  @Environment(\.stageLook) private var look

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 9).fill(look.accent)
      // Purple to green passes through teal, so the change is quick.
      RoundedRectangle(cornerRadius: 9).fill(look.success).opacity(sent ? 1 : 0).animation(.easeInOut(duration: 0.2), value: sent)
      // Each state is its own centered group, crossfading in place.
      ButtonState(on: step < 5) { Text("Pay out now") }
      ButtonState(on: step >= 5) {
        HStack(spacing: 7) {
          Check(on: sent, pending: !sent, size: 14, ring: .white.opacity(0.45), arc: .white, fill: .white, tick: look.success)
          // A Swap, so the group re-centers as "Sending" becomes "Sent".
          Swap(id: sent) { Text(sent ? "Sent" : "Sending") }
        }
      }
    }
    .font(.system(size: 12, weight: .medium))
    .foregroundStyle(.white)
    .frame(height: 36)
  }

  struct ButtonState<C: View>: View {
    let on: Bool
    @ViewBuilder let content: C
    var body: some View {
      content
        .opacity(on ? 1 : 0)
        .blur(radius: on ? 0 : 1)
        .animation(on ? .easeInOut(duration: 0.35).delay(0.12) : .easeInOut(duration: 0.18), value: on)
        .offset(y: on ? 0 : 4)
        .animation(on ? arrive.animation(0.5).delay(0.12) : .easeInOut(duration: 0.18), value: on)
    }
  }
}

private struct PayoutNote: View {
  let on: Bool
  @Environment(\.stageLook) private var look
  var body: some View {
    Text("Arrives in about 30 minutes")
      .line(11)
      .foregroundStyle(look.surface)
      .padding(.horizontal, 9).padding(.vertical, 5)
      .background(RoundedRectangle(cornerRadius: 7).fill(look.textStrong))
      .fixedSize()
      .target("note")
      .opacity(on ? 1 : 0)
      .animation(.easeInOut(duration: 0.6), value: on)
      .offset(y: on ? 0 : 8)
      .animation(spEase.animation(0.9), value: on)
  }
}

private func money(_ n: Double) -> String {
  n.formatted(.currency(code: "USD").locale(Locale(identifier: "en_US")))
}
