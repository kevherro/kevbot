import StageshowKit
import SwiftUI

// The smallest scene: a card rises in and a dot is tapped. Used to check
// the runner itself.
struct HelloScene: View {
  struct S: Equatable { var on = false }

  var body: some View {
    Stage(width: 358, height: 200, initial: S(), poster: S(on: true), cursor: StageCursor(at: .point(CGPoint(x: 300, y: 170)))) { a in
      try await a.wait(.milliseconds(400))
      a.mark("in")
      try await a.set { $0.on = true }
      try await a.click("dot")
      a.mark("tapped")
      try await a.wait(.milliseconds(800))
      try await a.snap { $0.on = false }
    } content: { s, _ in
      HelloCard(on: s.on)
    }
  }
}

private struct HelloCard: View {
  let on: Bool
  @Environment(\.stageLook) private var look
  var body: some View {
    RoundedRectangle(cornerRadius: 12)
      .fill(look.surface)
      .frame(width: 200, height: 100)
      .overlay(Circle().fill(look.accent).frame(width: 16, height: 16).target("dot"))
      .stageShadow(.hero)
      .offset(y: on ? 0 : 24)
      .opacity(on ? 1 : 0)
      .animation(.easeOut(duration: 0.6), value: on)
      .target("card")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
