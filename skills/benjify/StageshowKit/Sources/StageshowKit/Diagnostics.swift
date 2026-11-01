import Synchronization

// Live counts a soak test reads (through @testable import) to show a long
// loop leaks no acts, waiters or runs. Not public API.
enum Diagnostics {
  static let acts = Atomic<Int>(0)
  static let waiters = Atomic<Int>(0)
  static let runs = Atomic<Int>(0)

  static func snapshot() -> (acts: Int, waiters: Int, runs: Int) {
    (acts.load(ordering: .relaxed), waiters.load(ordering: .relaxed), runs.load(ordering: .relaxed))
  }
}
