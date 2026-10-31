import SwiftUI

/// The touch point, observed only by the dot that draws it, so a frame of
/// cursor travel never re-renders the scene.
@MainActor @Observable
final class CursorModel {
  var position: CGPoint = .zero
  var touching = false
  var pressed = false
  var swiping = false
  @ObservationIgnored var touch = 0

  func reset() {
    touching = false
    pressed = false
    swiping = false
    touch &+= 1
  }
}

// A finger, not glass: a soft gray dot that is there only while it touches.
struct TouchDot: View {
  let model: CursorModel
  var body: some View {
    let down = model.pressed || model.swiping
    Circle()
      .fill(Color(red: 118 / 255, green: 118 / 255, blue: 128 / 255).opacity(down ? 0.22 : 0.14))
      .frame(width: 34, height: 34)
      .scaleEffect(down ? 0.82 : model.touching ? 1 : 0.7)
      .opacity(model.touching ? 1 : 0)
      .animation(down ? .easeOut(duration: 0.1) : model.touching ? .timingCurve(0.22, 1, 0.36, 1, duration: 0.16) : .timingCurve(0.22, 1, 0.36, 1, duration: 0.45), value: down)
      .animation(model.touching ? .easeOut(duration: 0.14) : .easeOut(duration: 0.4), value: model.touching)
      .position(model.position)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
  }
}
