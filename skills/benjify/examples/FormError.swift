import StageshowKit
import SwiftUI

// Upstream: examples/form-error, at its compact (phone column) design,
// 358 x 420, without the browser Window: the form is already in an app, so
// it sits on the app's own ground, pinned top and sides, off the bottom.
// The cursor is a finger.
//
// A sign-up form catching a mistake. Beats: an email is typed without its
// ending; the field turns to error and the line under it says why; the
// ending is typed and the field turns valid; Create account is tapped, and
// the button settles on done. Plays once; the still is the payoff.
//
// - The message has a lane of its own under the field from the start: the
//   hint and the error swap in it (States), so the form never moves.
// - The error is said by the ring and the line together, and it leaves the
//   moment the value is fixed.
// - Nothing in the button moves sideways: the idle label and the busy group
//   are two layers in one place that crossfade.

struct FormError: View {
  struct S: Equatable {
    var email = ""
    var focused = true
    var status: Field.Status?
    var sending = false
    var done = false
  }

  var accessibilityLabel: String? = nil

  static let poster = S(email: "maya@northwind.co", focused: false, status: .valid, sending: true, done: true)

  static func script(_ a: Act<S>) async throws {
    try await a.wait(.milliseconds(700))
    a.mark("type")
    try await a.type(\.email, "maya@northwind", interval: .milliseconds(55))
    try await a.wait(.milliseconds(300))
    a.mark("error")
    a.put { $0.status = .error }
    try await a.wait(.milliseconds(1400))
    a.mark("fix")
    // Only the ending is typed: a.type would clear the field and start over.
    for end in ["maya@northwind.", "maya@northwind.c", "maya@northwind.co"] {
      a.put { $0.email = end }
      try await a.wait(.milliseconds(110))
    }
    a.put { $0.status = .valid }
    try await a.wait(.milliseconds(700))
    a.mark("send")
    try await a.click(.at("create", x: 0.5, y: 0.5))
    a.put { $0.focused = false; $0.sending = true }
    try await a.wait(.milliseconds(1200))
    a.put { $0.done = true }
    try await a.wait(.milliseconds(2400))
  }

  var body: some View {
    Stage(width: 358, height: 420, initial: S(), poster: Self.poster, play: .once,
          cursor: StageCursor(at: .point(CGPoint(x: 320, y: 390))), accessibilityLabel: accessibilityLabel,
          script: Self.script) { s, _ in
      FormScene(s: s)
    }
  }
}

private struct FormScene: View {
  let s: FormError.S
  @Environment(\.stageLook) private var look

  var body: some View {
    ZStack(alignment: .topLeading) {
      look.well
      FormCard(s: s)
        .target("card")
        .offset(x: 16, y: 38)
    }
    .frame(width: 358, height: 420, alignment: .topLeading)
    .clipped()
  }
}

private struct FormCard: View {
  let s: FormError.S
  @Environment(\.stageLook) private var look

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("Create your account")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(look.textStrong)
        .frame(height: FormMetrics.title)
        .padding(.bottom, 14)
      VStack(alignment: .leading, spacing: 6) {
        Field(label: "Work email", value: s.email, focused: s.focused, status: s.status)
          .overlay(alignment: .bottom) { Color.clear.frame(height: 34).target("email") }
        // One line, always there, so the error never moves the form.
        States(value: s.status == .error ? "error" : "hint", align: .leading, states: [
          "hint": Text("We'll send a link to confirm it").foregroundStyle(look.text),
          "error": Text(verbatim: "Add the domain, like name@company.com").foregroundStyle(look.dangerText),
        ])
        .font(.system(size: 11))
        .frame(maxWidth: .infinity, minHeight: 18, maxHeight: 18, alignment: .leading)
        .target("lane")
      }
      VStack(alignment: .leading, spacing: 6) {
        Field(label: "Password", value: "northwind-2026", password: true)
        Color.clear.frame(height: 18)
      }
      .padding(.top, 8)
      CreateButton(sending: s.sending, done: s.done)
        .target("create")
        .padding(.top, 6)
    }
    .padding(.horizontal, 22)
    .padding(.vertical, 24)
    .frame(width: 326, height: 382, alignment: .topLeading)
    .background(UnevenRoundedRectangle(topLeadingRadius: 12, topTrailingRadius: 12).fill(look.surface).stageShadow(.hero))
  }
}

// Line boxes measured from the upstream playground's "line-height: normal".
enum FormMetrics {
  static let title: CGFloat = 21
}

private struct CreateButton: View {
  let sending: Bool, done: Bool
  @Environment(\.stageLook) private var look

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8).fill(done ? look.success : look.accent)
        .animation(.easeInOut(duration: 0.3), value: done)
      Layer(on: !sending) { Text("Create account") }
      Layer(on: sending) {
        HStack(spacing: 8) {
          Check(on: done, pending: sending && !done, size: 14, ring: .white.opacity(0.45), arc: .white, fill: .white, tick: look.success)
          // Left-aligned in a cell as wide as the longer label.
          ZStack(alignment: .leading) {
            Layer(on: !done) { Text("Creating account") }
            Layer(on: done) { Text("Account created") }
          }
        }
      }
    }
    .font(.system(size: 13, weight: .semibold))
    .foregroundStyle(.white)
    .frame(height: 38)
  }

  struct Layer<C: View>: View {
    let on: Bool
    @ViewBuilder let content: C
    var body: some View {
      content
        .opacity(on ? 1 : 0)
        .blur(radius: on ? 0 : 1)
        .animation(.easeInOut(duration: 0.25).delay(on ? 0.08 : 0), value: on)
    }
  }
}
