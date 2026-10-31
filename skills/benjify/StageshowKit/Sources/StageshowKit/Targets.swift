import SwiftUI

/// Where the cursor aims: a named target's center, a point in the target,
/// a point in stage space, or a different target for each layout.
///
/// A string literal is a target name: `a.click("create")`.
public indirect enum Target: Sendable, Equatable, ExpressibleByStringLiteral {
  /// The center of the view marked `.target(name)`.
  case name(String)
  /// A point inside the named target, as fractions of its size.
  /// `x: 0.5, y: 0.5` is its center; values past 0...1 aim outside it.
  case at(String, x: CGFloat, y: CGFloat)
  /// A point in stage space (design points from the stage's top left).
  case point(CGPoint)
  /// One target for the wide design, another for the compact design.
  case perLayout(wide: Target, compact: Target)

  /// Creates a ``Target/name(_:)`` from a string literal.
  public init(stringLiteral value: String) { self = .name(value) }
}

/// The two designs a stage can show. `compact` is the narrow-container
/// design; see ``Stage``.
public enum StageLayout: String, Sendable, Equatable, Codable {
  /// The design at the stage's main size.
  case wide
  /// The design for containers narrower than ``CompactDesign/below``.
  case compact
}

/// Every target's rect in stage space at one moment, keyed by name.
///
/// Rects are in design points. Effects applied after `.target(_:)` or by
/// an ancestor (an `offset`, a `scaleEffect`) move the rect; effects applied
/// before it do not.
public struct Rects: Sendable, Equatable {
  /// The rects by target name.
  public internal(set) var byName: [String: CGRect]

  /// Creates a set of rects.
  public init(_ byName: [String: CGRect] = [:]) { self.byName = byName }

  /// The named target's rect, or `nil` when no view carries that target.
  public subscript(_ name: String) -> CGRect? { byName[name] }
}

// One preference carries both the anchors and the generation of the body
// that produced them, so a waiter can tell a fresh publish from a stale one.
struct Targets: Equatable {
  var gen: Int = -1
  var anchors: [String: Anchor<CGRect>] = [:]
}

struct TargetsKey: PreferenceKey {
  static let defaultValue = Targets()
  static func reduce(value: inout Targets, nextValue: () -> Targets) {
    let next = nextValue()
    value.gen = max(value.gen, next.gen)
    value.anchors.merge(next.anchors) { _, new in new }
  }
}

extension View {
  /// Names this view so a script can measure it (`a.rect`) and aim at it
  /// (`a.click`, `a.move`). Names are unique within a stage.
  ///
  /// Effects applied before `.target` (closer to the view) are left out of
  /// its rect; effects applied after it, or by an ancestor, are included.
  /// So `.offset(y: 24).target("card")` measures where the card rests, and
  /// `.target("card").offset(y: 24)` measures where it is drawn.
  public func target(_ name: String) -> some View {
    modifier(TargetModifier(name: name))
  }
}

struct TargetModifier: ViewModifier {
  let name: String
  @Environment(\.stageInstantScopes) private var instant
  func body(content: Content) -> some View {
    let snapping = instant.contains(name)
    content
      .transaction { t in if snapping { t.disablesAnimations = true; t.animation = nil } }
      .environment(\.stageInstant, snapping)
      // Merge, not replace: a target can hold other targets.
      .transformAnchorPreference(key: TargetsKey.self, value: .bounds) { $0.anchors[name] = $1 }
  }
}

/// Holds the latest published rects and resumes `set()` callers waiting
/// for a generation. Written from the stage's geometry reader during a view
/// update; never observed by SwiftUI, so writing it cannot invalidate a view.
@MainActor
final class RectStore {
  private(set) var rects = Rects()
  private(set) var gen = -1
  private(set) var publishes = 0
  fileprivate(set) var chars: [String: [CaretChar]] = [:]
  private var waiters: [(id: Int, gen: Int, resume: CheckedContinuation<Void, any Error>)] = []
  private var nextWaiter = 0

  func publish(gen: Int, rects: Rects) {
    publishes += 1
    self.rects = rects
    self.gen = max(self.gen, gen)
    guard !waiters.isEmpty else { return }
    let ready = waiters.filter { $0.gen <= self.gen }
    waiters.removeAll { $0.gen <= self.gen }
    for w in ready { w.resume.resume() }
  }

  /// Returns once a publish of generation `wanted` or later has arrived.
  func published(_ wanted: Int) async throws {
    if gen >= wanted { return }
    let id = nextWaiter
    nextWaiter += 1
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, any Error>) in
        if Task.isCancelled { c.resume(throwing: CancellationError()); return }
        waiters.append((id, wanted, c))
      }
    } onCancel: {
      Task { @MainActor in self.cancel(id) }
    }
  }

  private func cancel(_ id: Int) {
    guard let i = waiters.firstIndex(where: { $0.id == id }) else { return }
    waiters.remove(at: i).resume.resume(throwing: CancellationError())
  }

  var pendingWaiters: Int { waiters.count }
}

extension RectStore {
  func setChars(_ chars: [String: [CaretChar]]) { self.chars = chars }
}
