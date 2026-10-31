import SwiftUI

/// Named cubic-bezier curves, as upstream Stageshow names them.
public enum Ease: Sendable {
  /// Moves inside a shot: peak at about 40%, long soft tail.
  case house
  /// The outgoing half of a move that ends in a cut.
  case through
  /// The incoming half after a cut: arrives at speed, settles.
  case settle
  /// A cursor arriving from off-frame, already moving.
  case enter
  /// One long cursor trip across the frame.
  case trip
  /// A custom `cubic-bezier(x1, y1, x2, y2)`.
  case bezier(Double, Double, Double, Double)

  var points: (Double, Double, Double, Double) {
    switch self {
    case .house: (0.65, 0, 0.1, 1)
    case .through: (0.8, 0, 0.1, 1)
    case .settle: (0.05, 0.85, 0.3, 1)
    case .enter: (0.1, 0.8, 0.3, 0.95)
    case .trip: (0.78, 0, 0.17, 1)
    case let .bezier(a, b, c, d): (a, b, c, d)
    }
  }

  /// The curve as a SwiftUI animation of `duration` seconds.
  public func animation(_ duration: Double) -> Animation {
    let (a, b, c, d) = points
    return .timingCurve(a, b, c, d, duration: duration)
  }

  /// Progress at time `t` (0...1), the way CSS evaluates the curve.
  public func callAsFunction(_ t: Double) -> Double {
    let (x1, y1, x2, y2) = points
    return UnitCurve.bezier(startControlPoint: UnitPoint(x: x1, y: y1), endControlPoint: UnitPoint(x: x2, y: y2)).value(at: t)
  }
}

func easeInOutCubic(_ t: Double) -> Double {
  t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2
}

func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T { min(hi, max(lo, v)) }

// Uneven but repeatable typing rhythm, as upstream's util.hash.
func rhythm(_ i: Int) -> Double {
  let x = sin(Double(i) * 12.9898) * 43758.5453
  return x - floor(x)
}
