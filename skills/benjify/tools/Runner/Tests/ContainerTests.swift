import SwiftUI
import Testing
import UIKit
@testable import StageshowKit

// set() and rect() where SwiftUI may lay a view out more than once or
// lazily. The stage publishes rects from its geometry reader during a view
// update; each container gets 50 sets that move a target, and every rect
// read after a set must be the new one.

@MainActor
@Suite(.serialized)
struct ContainerTests {
  struct S: Equatable { var x: CGFloat = 0 }

  @MainActor final class Result { var fresh = 0; var done = false; var marks: [Mark] = [] }

  static func stage(_ r: Result) -> some View {
    Stage(width: 300, height: 80, initial: S(), play: .once) { a in
      for i in 1...50 {
        let x = CGFloat(i * 4)
        try await a.set { $0.x = x }
        if a.rect("box")?.minX == x { r.fresh += 1 }
      }
      a.mark("end")
      r.marks = a.model.marks
      r.done = true
    } content: { s, _ in
      HStack(spacing: 0) { Color.clear.frame(width: s.x, height: 1); Color.red.frame(width: 20, height: 20).target("box") }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  func run(_ name: String, _ host: (Result) -> AnyView) async -> Result {
    let r = Result()
    let w = Host.show(host(r))
    defer { w.isHidden = true }
    for _ in 0..<60 where !r.done { await Host.pause(100) }
    print("MEASURE container.\(name) fresh=\(r.fresh)/50 done=\(r.done)")
    return r
  }

  @Test func scrollView() async {
    let r = await run("ScrollView") { r in AnyView(ScrollView { VStack { Color.gray.frame(height: 100); Self.stage(r); Color.gray.frame(height: 900) } }) }
    #expect(r.done && r.fresh == 50)
  }

  @Test func list() async {
    let r = await run("List") { r in AnyView(List { Text("Row"); Self.stage(r); ForEach(0..<20, id: \.self) { Text("Row \($0)") } }) }
    #expect(r.done && r.fresh == 50)
  }

  @Test func lazyVStack() async {
    let r = await run("LazyVStack") { r in AnyView(ScrollView { LazyVStack { ForEach(0..<3, id: \.self) { _ in Color.gray.frame(height: 50) }; Self.stage(r) } }) }
    #expect(r.done && r.fresh == 50)
  }

  @Test func viewThatFits() async {
    let r = await run("ViewThatFits") { r in AnyView(ViewThatFits { HStack { Self.stage(r).frame(width: 300); Color.gray.frame(width: 300) }; Self.stage(r) }) }
    #expect(r.done && r.fresh == 50)
  }

  @Test func sheet() async {
    struct V: View { let r: Result; @State var on = false
      var body: some View { Color.white.sheet(isPresented: $on) { ContainerTests.stage(r) }.task { on = true } }
    }
    let r = await run("sheet") { r in AnyView(V(r: r)) }
    #expect(r.done && r.fresh == 50)
  }

  @Test func navigationPush() async {
    struct V: View { let r: Result; @State var path: [Int] = []
      var body: some View {
        NavigationStack(path: $path) {
          Text("Root").navigationDestination(for: Int.self) { _ in ContainerTests.stage(r) }
        }
        .task { path = [1] }
      }
    }
    let r = await run("NavigationStack") { r in AnyView(V(r: r)) }
    #expect(r.done && r.fresh == 50)
  }

  // Scrolled off inside a ScrollView: which signal fires. A plain stack
  // keeps the view and reports it hidden; a lazy stack unloads it first,
  // so only onDisappear fires. The stage listens to both.
  @Test(arguments: [false, true])
  func scrolledOffSignals(_ lazy: Bool) async {
    @MainActor final class Seen: ObservableObject { var disappear = 0; var hidden = 0; @Published var pos = ScrollPosition(y: 0) }
    struct V: View { @ObservedObject var seen: Seen; let lazy: Bool
      var body: some View {
        ScrollView {
          let probe = Color.red.frame(height: 100)
            .onDisappear { seen.disappear += 1 }
            .onScrollVisibilityChange(threshold: 0.01) { if !$0 { seen.hidden += 1 } }
          if lazy {
            LazyVStack(spacing: 0) { probe; ForEach(0..<60, id: \.self) { _ in Color.gray.frame(height: 100) } }
          } else {
            VStack(spacing: 0) { probe; ForEach(0..<60, id: \.self) { _ in Color.gray.frame(height: 100) } }
          }
        }
        .scrollPosition($seen.pos)
      }
    }
    let seen = Seen()
    let w = Host.show(V(seen: seen, lazy: lazy))
    defer { w.isHidden = true }
    await Host.pause(300)
    seen.pos = ScrollPosition(y: 4000)
    await Host.pause(500)
    print("MEASURE container.scrolledOff lazy=\(lazy) onDisappear=\(seen.disappear) onScrollVisibilityChange(false)=\(seen.hidden)")
    #expect(seen.hidden == (lazy ? 0 : 1))
    #expect(seen.disappear == (lazy ? 1 : 0))
  }
}
