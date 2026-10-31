import Foundation
import Synchronization

/// A clock that moves only when a test advances it.
final class ManualClock: Clock, Sendable {
  struct Instant: InstantProtocol {
    var offset: Duration
    func advanced(by d: Duration) -> Instant { Instant(offset: offset + d) }
    func duration(to other: Instant) -> Duration { other.offset - offset }
    static func < (a: Instant, b: Instant) -> Bool { a.offset < b.offset }
  }

  private struct Sleeper { let id: Int; let deadline: Instant; let resume: CheckedContinuation<Void, any Error> }
  private struct State { var now = Instant(offset: .zero); var sleepers: [Sleeper] = []; var next = 0 }
  private let state = Mutex(State())

  var now: Instant { state.withLock { $0.now } }
  var minimumResolution: Duration { .zero }
  var sleeping: Int { state.withLock { $0.sleepers.count } }

  func sleep(until deadline: Instant, tolerance: Duration?) async throws {
    let id = state.withLock { s in s.next += 1; return s.next }
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, any Error>) in
        let due = state.withLock { s -> Bool in
          if deadline <= s.now { return true }
          s.sleepers.append(Sleeper(id: id, deadline: deadline, resume: c))
          return false
        }
        if due { c.resume() }
      }
    } onCancel: {
      let s = state.withLock { s -> Sleeper? in
        guard let i = s.sleepers.firstIndex(where: { $0.id == id }) else { return nil }
        return s.sleepers.remove(at: i)
      }
      s?.resume.resume(throwing: CancellationError())
    }
  }

  /// Moves time forward and wakes every sleeper now due.
  func advance(by d: Duration) {
    let due = state.withLock { s -> [Sleeper] in
      s.now = s.now.advanced(by: d)
      let ready = s.sleepers.filter { $0.deadline <= s.now }
      s.sleepers.removeAll { $0.deadline <= s.now }
      return ready
    }
    for s in due { s.resume.resume() }
  }
}
