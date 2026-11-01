import SwiftUI

// Form controls with their motion done. Upstream: controls/Field,
// motion/States.

/// A text field: label, box, value and caret. The focus ring fades in
/// without moving the text, the placeholder leaves the moment the first
/// character lands, and the caret sits solid while typing, blinking only
/// once it rests. `status` turns the ring to danger or draws a check.
/// Put `.target` on it to aim at the box. Upstream: `Field` (no chip).
public struct Field: View {
  /// What a field is saying about its value.
  public enum Status: Sendable {
    /// A check at the end and a calm ring.
    case valid
    /// The ring turns to danger.
    case error
  }

  let label: String?, value: String, placeholder: String?, focused: Bool, password: Bool, status: Status?
  @Environment(\.stageLook) private var look
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  /// Creates a field. Drive `value` with `Act.type`.
  public init(label: String? = nil, value: String, placeholder: String? = nil, focused: Bool = false, password: Bool = false, status: Status? = nil) {
    self.label = label; self.value = value; self.placeholder = placeholder
    self.focused = focused; self.password = password; self.status = status
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let quiet = still || instant
    let ring: (Color, Color) = status == .error ? (look.danger, look.dangerSoft) : focused ? (look.accent, look.accentSoft) : (look.ink(4), .clear)
    VStack(alignment: .leading, spacing: 6) {
      if let label {
        // 13pt: upstream's 11.5px label at line-height normal, as Chrome draws it.
        Text(label).font(.system(size: 11.5, weight: .medium)).foregroundStyle(look.textStrong).frame(height: 13)
      }
      HStack(spacing: 8) {
        ZStack(alignment: .leading) {
          if let placeholder {
            Text(placeholder).foregroundStyle(look.textFaint)
              .opacity(value.isEmpty ? 1 : 0)
              .animation(value.isEmpty && !quiet ? .easeInOut(duration: 0.2) : nil, value: value.isEmpty)
          }
          HStack(spacing: 0) {
            Text(password ? String(repeating: "•", count: value.count) : value)
              .tracking(password ? 1.5 : 0)
              .lineLimit(1)
            if focused { FieldCaret(color: look.accent, typed: value.count, blinking: !quiet).padding(.leading, 1) }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipped()
        if status == .valid {
          OKMark(color: look.success, quiet: quiet).frame(width: 14, height: 14)
        }
      }
      .font(.system(size: 13))
      .foregroundStyle(look.textStrong)
      .padding(.horizontal, 11)
      .frame(height: 34)
      .background {
        // The ring is a stroke, so focusing never moves the text.
        RoundedRectangle(cornerRadius: 8).fill(look.surface)
          .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(ring.0, lineWidth: 1))
          .background(RoundedRectangle(cornerRadius: 11).stroke(ring.1, lineWidth: 3).padding(-1.5))
          .animation(quiet ? nil : .easeInOut(duration: 0.2), value: status == .error)
          .animation(quiet ? nil : .easeInOut(duration: 0.2), value: focused)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(label ?? "")
    .accessibilityValue(password ? "" : value)
  }
}

// Solid while typing (each keystroke restarts it), blinking at rest.
private struct FieldCaret: View {
  let color: Color, typed: Int, blinking: Bool
  @State private var lastType = Date.distantPast
  var body: some View {
    TimelineView(.animation(paused: !blinking)) { ctx in
      let since = ctx.date.timeIntervalSince(lastType) - 0.5
      let off = blinking && since > 0 && since.truncatingRemainder(dividingBy: 1.06) >= 0.53
      RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 1.5, height: 16).opacity(off ? 0 : 1)
    }
    .onChange(of: typed, initial: true) { lastType = .now }
  }
}

// The valid check, drawn in as it appears.
private struct OKMark: View {
  let color: Color, quiet: Bool
  @State private var drawn = false
  var body: some View {
    OKPath()
      .trim(from: 0, to: drawn || quiet ? 1 : 0)
      .stroke(color, style: StrokeStyle(lineWidth: 2 * 14 / 16, lineCap: .round, lineJoin: .round))
      .onAppear { withAnimation(.timingCurve(0.65, 0, 0.35, 1, duration: 0.35)) { drawn = true } }
  }

  struct OKPath: Shape {
    func path(in r: CGRect) -> Path {
      let s = r.width / 16
      var p = Path()
      p.move(to: CGPoint(x: 3.5 * s, y: 8.5 * s))
      p.addLine(to: CGPoint(x: 6.5 * s, y: 11.5 * s))
      p.addLine(to: CGPoint(x: 12.5 * s, y: 4.5 * s))
      return p
    }
  }
}

/// A control's states (label, spinner, done) stacked in one place and
/// crossfaded: the outgoing state is mostly gone as the next arrives, and
/// the box holds the largest state, so nothing around it shifts. `align`
/// places a smaller state in the box. Not for a label centered with an
/// icon whose box must resize: use ``Swap`` there.
public struct States<Key: Hashable>: View {
  let value: Key
  let states: [(Key, AnyView)]
  let align: Alignment
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  /// Creates stacked states. Order sets which draws on top.
  public init(value: Key, align: HorizontalAlignment = .center, states: KeyValuePairs<Key, some View>) {
    self.value = value
    self.states = states.map { ($0.key, AnyView($0.value)) }
    self.align = Alignment(horizontal: align, vertical: .center)
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let quiet = still || instant
    ZStack(alignment: align) {
      ForEach(states.indices, id: \.self) { i in
        let on = states[i].0 == value
        states[i].1
          .opacity(on ? 1 : 0)
          .blur(radius: on || quiet ? 0 : 1)
          .animation(quiet ? nil : on ? .easeOut(duration: 0.25).delay(0.07) : .easeInOut(duration: 0.15), value: on)
          .offset(y: on || quiet ? 0 : 4)
          .animation(quiet ? nil : on ? .timingCurve(0.22, 1, 0.36, 1, duration: 0.3).delay(0.07) : .linear(duration: 0.01).delay(0.15), value: on)
          .accessibilityHidden(!on)
      }
    }
  }
}
