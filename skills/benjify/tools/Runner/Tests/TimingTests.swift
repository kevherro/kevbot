import SwiftUI
import Testing
@testable import StageshowKit

@MainActor
@Suite(.serialized)
struct TimingTests {
  struct S: Equatable { var go = false }

  // How late a.wait returns, with an animation running on the stage.
  @Test func waitOvershoot() async throws {
    var late: [Double] = []
    try await Harness.run(S()) { s, _ in
      Color.black.frame(width: 8, height: 100).offset(x: s.go ? 300 : 0).animation(.linear(duration: 3), value: s.go)
    } script: { a in
      a.put { $0.go = true }
      for _ in 0..<6 {
        let t0 = ContinuousClock.now
        try await a.wait(.milliseconds(500))
        late.append(((ContinuousClock.now - t0).seconds - 0.5) * 1000)
      }
    }
    print("MEASURE timing.waitOvershoot ms=\(late.map { String(format: "%.1f", $0) })")
    #expect(late.allSatisfy { $0 >= 0 && $0 < 20 })
  }
}
