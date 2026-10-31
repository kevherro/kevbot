import SwiftUI

/// How much of a scene is real words. `Bar` and ``SceneText`` read it.
public enum Fidelity: String, Sendable {
  /// Every line is a placeholder bar.
  case minimal
  /// Real words where they carry meaning; filler is bars.
  case standard
  /// Real words everywhere, filler included.
  case realistic
}

/// The color tokens a scene draws with, after upstream's `--ss-*` tokens.
/// Read it with `@Environment(\.stageLook)`; a ``Stage`` sets it for the
/// color scheme it is drawn in.
public struct StageLook: Sendable, Equatable {
  /// Placeholder inks, faintest first (`--ss-ink-1` to `-5`).
  public var ink: [Color]
  /// The page under a scene (`--ss-canvas`).
  public var canvas: Color
  /// A card or window body (`--ss-surface`).
  public var surface: Color
  /// A satellite card over the surface (`--ss-raised`).
  public var raised: Color
  /// A recessed well (`--ss-well`).
  public var well: Color
  /// Rules between rows.
  public var line: Color
  /// Faint rules between rows.
  public var lineFaint: Color
  /// Secondary text.
  public var text: Color
  /// Primary text.
  public var textStrong: Color
  /// Placeholder text.
  public var textFaint: Color
  /// The one accent color.
  public var accent: Color
  /// The accent's soft fill.
  public var accentSoft: Color
  /// Success, its soft fill and its text shade.
  public var success: Color, successSoft: Color, successText: Color
  /// Danger, its soft fill and its text shade.
  public var danger: Color, dangerSoft: Color, dangerText: Color
  /// Whether these are the dark tokens.
  public var isDark: Bool

  /// The light tokens.
  public static let light = StageLook(
    ink: [.black.opacity(0.04), .black.opacity(0.06), .black.opacity(0.08), .black.opacity(0.1), .black.opacity(0.15)],
    canvas: Color(hex: 0xF6F5F4), surface: .white, raised: .white, well: Color(hex: 0xEFEEEC),
    line: .black.opacity(0.06), lineFaint: .black.opacity(0.04),
    text: Color(hex: 0x7A7A7D), textStrong: Color(hex: 0x262628), textFaint: Color(hex: 0x9A9A9D),
    accent: Color(hex: 0x3B82F6), accentSoft: Color(hex: 0x3B82F6).opacity(0.12),
    success: Color(hex: 0x22C55E), successSoft: Color(hex: 0x22C55E).opacity(0.12), successText: Color(hex: 0x15803D),
    danger: Color(hex: 0xEF4444), dangerSoft: Color(hex: 0xEF4444).opacity(0.1), dangerText: Color(hex: 0xB91C1C),
    isDark: false)

  /// The dark tokens.
  public static let dark = StageLook(
    ink: [.white.opacity(0.05), .white.opacity(0.07), .white.opacity(0.1), .white.opacity(0.13), .white.opacity(0.2)],
    canvas: Color(hex: 0x111113), surface: Color(hex: 0x1A1A1D), raised: Color(hex: 0x26262A), well: Color(hex: 0x0A0A0B),
    line: .white.opacity(0.08), lineFaint: .white.opacity(0.05),
    text: Color(hex: 0x9D9DA1), textStrong: Color(hex: 0xECECEE), textFaint: Color(hex: 0x6C6C70),
    accent: Color(hex: 0x3B82F6), accentSoft: Color(hex: 0x3B82F6).opacity(0.2),
    success: Color(hex: 0x22C55E), successSoft: Color(hex: 0x22C55E).opacity(0.16), successText: Color(hex: 0x4ADE80),
    danger: Color(hex: 0xEF4444), dangerSoft: Color(hex: 0xEF4444).opacity(0.16), dangerText: Color(hex: 0xF87171),
    isDark: true)

  /// These tokens with a different accent and its soft fill.
  public func accent(_ color: Color) -> StageLook {
    var l = self
    l.accent = color
    l.accentSoft = color.opacity(isDark ? 0.2 : 0.12)
    return l
  }

  /// A placeholder ink, 1 (faintest) to 5.
  public func ink(_ tone: Int) -> Color { ink[clamp(tone, 1, 5) - 1] }
}

/// The two elevation shadows upstream names `--ss-shadow-hero` and
/// `--ss-shadow-satellite`.
public enum StageShadow: Sendable {
  /// The leading object's shadow.
  case hero
  /// A smaller second object's shadow.
  case satellite
}

extension View {
  /// Draws one of the look's elevation shadows, for light or dark.
  public func stageShadow(_ kind: StageShadow) -> some View { modifier(ShadowModifier(kind: kind)) }
}

struct ShadowModifier: ViewModifier {
  let kind: StageShadow
  @Environment(\.stageLook) private var look
  func body(content: Content) -> some View {
    let d = look.isDark
    switch kind {
    case .hero:
      content
        .shadow(color: (d ? Color.white.opacity(0.08) : Color.black.opacity(0.06)), radius: 0.5)
        .shadow(color: d ? .black.opacity(0.6) : Color(red: 50 / 255, green: 50 / 255, blue: 93 / 255).opacity(0.25), radius: 24, y: 24)
        .shadow(color: .black.opacity(d ? 0 : 0.3), radius: 10, y: 14)
    case .satellite:
      content
        .shadow(color: (d ? Color.white.opacity(0.1) : Color.black.opacity(0.04)), radius: 0.5)
        .shadow(color: d ? .black.opacity(0.7) : Color(red: 50 / 255, green: 50 / 255, blue: 93 / 255).opacity(0.24), radius: 13, y: 12)
        .shadow(color: .black.opacity(d ? 0.5 : 0.1), radius: 4, y: 3)
    }
  }
}

extension EnvironmentValues {
  /// The tokens of the stage this view is drawn in.
  @Entry public var stageLook: StageLook = .light
  /// The fidelity of the stage this view is drawn in.
  @Entry public var stageFidelity: Fidelity = .standard
  /// True when the stage shows a still: reduced motion, no script, or a
  /// snap in progress. Parts skip their own motion while it is true.
  @Entry public var stageStill: Bool = false
  /// The layout of the stage this view is drawn in.
  @Entry public var stageLayout: StageLayout = .wide
}

extension Color {
  /// A color from a 0xRRGGBB literal.
  public init(hex: UInt32) {
    self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
  }
}
