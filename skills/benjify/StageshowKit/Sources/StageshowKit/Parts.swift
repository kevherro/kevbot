import SwiftUI

// Small parts: placeholder bars, fidelity-aware text, icons, and the
// status check. Upstream: window.tsx (Bar, Text), parts/Icon, parts/Check.

/// A placeholder: a line of text, a value, an icon slot or a pill.
///
/// A line (a width over three times its height) gives way in a row too
/// narrow for it and never runs past its container; where it fits it is
/// exactly `w`. An icon slot or a dot keeps its size. `shrink` overrides
/// either way.
public struct Bar: View {
  let w: CGFloat, h: CGFloat, tone: Int, r: CGFloat, shrink: Bool?
  @Environment(\.stageLook) private var look

  /// Creates a bar `w` by `h` points in ink `tone` (1 faintest to 5).
  public init(w: CGFloat, h: CGFloat = 6, tone: Int = 3, r: CGFloat = 2, shrink: Bool? = nil) {
    self.w = w; self.h = h; self.tone = tone; self.r = r; self.shrink = shrink
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let gives = shrink ?? (w > h * 3)
    RoundedRectangle(cornerRadius: r)
      .fill(look.ink(tone))
      .frame(minWidth: gives ? 0 : w, idealWidth: w, maxWidth: w)
      .frame(height: h)
      .layoutPriority(gives ? -1 : 0)
  }
}

/// Text that knows the stage's fidelity: real words normally, a bar of
/// about the same width at `.minimal`. With `filler`, the words show only
/// at `.realistic` and are a bar otherwise, so filler is written once and
/// the stage decides. One line unless `wrap`. Upstream: `Text`.
public struct SceneText: View {
  let text: String, filler: Bool, size: CGFloat, w: CGFloat?, h: CGFloat, tone: Int, wrap: Bool
  @Environment(\.stageFidelity) private var fidelity

  /// Creates scene text. `size` is the font size the bar's width is
  /// estimated from (set `w` to be exact); it does not set the font.
  public init(_ text: String, filler: Bool = false, size: CGFloat = 11, w: CGFloat? = nil, h: CGFloat = 6, tone: Int = 3, wrap: Bool = false) {
    self.text = text; self.filler = filler; self.size = size; self.w = w; self.h = h; self.tone = tone; self.wrap = wrap
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    if fidelity == .minimal || (filler && fidelity != .realistic) {
      Bar(w: w ?? (CGFloat(text.count) * size * 0.52).rounded(), h: h, tone: tone)
    } else {
      Text(text).lineLimit(wrap ? nil : 1)
    }
  }
}

/// Upstream's icon names, drawn with SF Symbols. `filled` uses the solid
/// variant. The product's own icons belong to the product: use them in
/// place of these when it has them.
public enum IconName: String, Sendable, CaseIterable {
  case check, plus, close, chevronRight = "chevron-right", chevronDown = "chevron-down", search, globe
  case external, clock, archive, trash, more, arrow, file, user, bell, card, bolt, lock, play, pause
  case faceid, wifi, heart, star, calendar, mail, send, home, gear, grip

  var symbol: String {
    switch self {
    case .check: "checkmark"
    case .plus: "plus"
    case .close: "xmark"
    case .chevronRight: "chevron.right"
    case .chevronDown: "chevron.down"
    case .search: "magnifyingglass"
    case .globe: "globe"
    case .external: "arrow.up.right"
    case .clock: "clock"
    case .archive: "archivebox"
    case .trash: "trash"
    case .more: "ellipsis"
    case .arrow: "arrow.right"
    case .file: "doc"
    case .user: "person"
    case .bell: "bell"
    case .card: "creditcard"
    case .bolt: "bolt"
    case .lock: "lock"
    case .play: "play"
    case .pause: "pause"
    case .faceid: "faceid"
    case .wifi: "wifi"
    case .heart: "heart"
    case .star: "star"
    case .calendar: "calendar"
    case .mail: "envelope"
    case .send: "paperplane"
    case .home: "house"
    case .gear: "gearshape"
    case .grip: "line.3.horizontal"
    }
  }

  // Symbols with a solid variant; the rest draw the same either way.
  var hasFill: Bool {
    switch self {
    case .check, .plus, .close, .chevronRight, .chevronDown, .search, .external, .more, .arrow, .grip, .faceid, .wifi, .calendar: false
    default: true
    }
  }
}

/// A small icon in the foreground style, `size` points square. Upstream:
/// `Icon` (lucide glyphs and a few drawn solids; here SF Symbols).
public struct Icon: View {
  let name: IconName, size: CGFloat, filled: Bool

  /// Creates an icon. `filled` gives the solid glyph, which reads better
  /// at 14pt and under and inside tinted tiles.
  public init(_ name: IconName, size: CGFloat = 16, filled: Bool = false) {
    self.name = name; self.size = size; self.filled = filled
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    Image(systemName: name.symbol + (filled && name.hasFill ? ".fill" : ""))
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .accessibilityHidden(true)
  }
}

/// A status circle. `pending` turns an arc inside the ring; `on` grows a
/// solid disc from the center and then draws the tick. Pending hands over
/// to done in one mark, never a spinner over a check, and the tick fades
/// out intact rather than undrawing. Colors default to the look's.
public struct Check: View {
  let on: Bool, pending: Bool, size: CGFloat
  let ring: Color?, arc: Color?, fill: Color?, tick: Color?
  @Environment(\.stageLook) private var look
  @Environment(\.stageStill) private var still
  @Environment(\.stageInstant) private var instant

  /// Creates a check. Pass colors to restyle it on a filled button.
  public init(on: Bool, pending: Bool = false, size: CGFloat = 16, ring: Color? = nil, arc: Color? = nil, fill: Color? = nil, tick: Color? = nil) {
    self.on = on; self.pending = pending; self.size = size
    self.ring = ring; self.arc = arc; self.fill = fill; self.tick = tick
  }

  /// The part, drawn from its inputs.
  public var body: some View {
    let k = size / 16
    let quiet = still || instant
    let spinning = pending && !on
    ZStack {
      Circle().inset(by: 0.75 * k).stroke(ring ?? look.ink(4), lineWidth: 1.5 * k)
        .opacity(on ? 0 : 1)
        .animation(quiet ? nil : .easeInOut(duration: 0.2), value: on)
      Spinner(color: arc ?? look.textStrong, k: k, spinning: spinning && !quiet)
        .opacity(spinning ? 1 : 0)
        .animation(quiet ? nil : .easeInOut(duration: on ? 0.08 : 0.18), value: spinning)
      Circle().fill(fill ?? look.success)
        .scaleEffect(on ? 1 : 0.35)
        .opacity(on ? 1 : 0)
        .animation(quiet ? nil : on ? .timingCurve(0.22, 1, 0.36, 1, duration: 0.4) : .easeInOut(duration: 0.2), value: on)
      TickShape()
        .trim(from: 0, to: on ? 1 : 0)
        .stroke(tick ?? (look.isDark ? Color(hex: 0x111111) : .white), style: StrokeStyle(lineWidth: 1.8 * k, lineCap: .round, lineJoin: .round))
        // Draws in once the disc is mostly there; leaving, it fades intact
        // (the trim snaps back only after the fade). The nearest animation
        // modifier wins, so the trim's comes first and the opacity's after.
        .animation(quiet ? nil : on ? .timingCurve(0.65, 0, 0.35, 1, duration: 0.32).delay(0.16) : .linear(duration: 0.01).delay(0.2), value: on)
        .opacity(on ? 1 : 0)
        .animation(quiet ? nil : on ? .linear(duration: 0.01).delay(0.16) : .easeInOut(duration: 0.2), value: on)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }

  struct Spinner: View {
    let color: Color, k: CGFloat, spinning: Bool
    var body: some View {
      TimelineView(.animation(paused: !spinning)) { ctx in
        let turns = ctx.date.timeIntervalSinceReferenceDate / 0.8
        Circle().inset(by: 0.75 * k)
          .trim(from: 0, to: 0.28)
          .stroke(color, style: StrokeStyle(lineWidth: 1.5 * k, lineCap: .round))
          .rotationEffect(.degrees((turns - turns.rounded(.down)) * 360 - 90))
      }
    }
  }

  struct TickShape: Shape {
    func path(in r: CGRect) -> Path {
      let s = r.width / 16
      var p = Path()
      p.move(to: CGPoint(x: 4.5 * s, y: 8.2 * s))
      p.addLine(to: CGPoint(x: 7 * s, y: 10.6 * s))
      p.addLine(to: CGPoint(x: 11.6 * s, y: 5.6 * s))
      return p
    }
  }
}
