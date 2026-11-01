import StageshowKit
import SwiftUI

// One tile per ported part, cycling its states: a catalog, not a
// composition. Upstream: examples/parts, kit-extras, controls.
struct PartsSpecimen: View {
  struct S: Equatable { var on = false; var n = 1240.0; var label = "Pending"; var field = ""; var status = 0 }

  var body: some View {
    Stage(width: 358, height: 560, initial: S(), poster: S(on: true, n: 1250, label: "Paid", field: "maya@northwind.co", status: 2), cursor: StageCursor(at: .point(CGPoint(x: 300, y: 520)))) { a in
      try await a.wait(.milliseconds(500))
      a.mark("rest")
      try await a.set { $0.on = true; $0.n = 1250; $0.label = "Paid"; $0.status = 1 }
      try await a.type(\.field, "maya@northwind.co", interval: .milliseconds(40))
      try await a.set { $0.status = 2 }
      try await a.wait(.milliseconds(1200))
      a.mark("on")
      try await a.click("check")
      try await a.snap { $0 = S() }
      try await a.wait(.milliseconds(400))
    } content: { s, _ in
      Tiles(s: s)
    } overlay: { s, rects, _ in
      if let a = rects["from"], let b = rects["to"] {
        Connector(from: CGPoint(x: a.maxX, y: a.midY), to: CGPoint(x: b.minX, y: b.midY), route: .step, show: s.on, arrow: true, label: "POST")
      }
    }
  }

  struct Tiles: View {
    let s: S
    @Environment(\.stageLook) private var look
    var body: some View {
      VStack(alignment: .leading, spacing: 18) {
        HStack(spacing: 10) { Bar(w: 120); Bar(w: 60, tone: 2); Bar(w: 18, h: 18, tone: 4, r: 5); Bar(w: 6, h: 6, tone: 5, r: 3) }
        HStack(spacing: 12) {
          SceneText("Standard words").font(.system(size: 13))
          SceneText("Filler line", filler: true, size: 13)
          SceneText("Minimal", size: 13).environment(\.stageFidelity, .minimal)
        }
        HStack(spacing: 10) { ForEach(IconName.allCases.prefix(12), id: \.self) { Icon($0, size: 18) } }
        HStack(spacing: 10) { ForEach(IconName.allCases.suffix(12), id: \.self) { Icon($0, size: 18, filled: true) } }
        HStack(spacing: 16) {
          Check(on: false)
          Check(on: s.on, pending: !s.on).target("check")
          Check(on: true)
          Count(s.n, format: { String(format: "%.0f", $0) }).font(.system(size: 22, weight: .semibold))
          Roll(s.label, variant: .fade).font(.system(size: 13, weight: .medium))
          Swap(id: s.on) { Text(s.on ? "Sent" : "Sending") }.font(.system(size: 13))
        }
        HStack {
          Text("Client").padding(8).background(RoundedRectangle(cornerRadius: 6).fill(look.ink(2))).target("from")
          Spacer()
          Text("API").padding(8).background(RoundedRectangle(cornerRadius: 6).fill(look.ink(2))).target("to")
        }
        .frame(height: 70)
        Field(label: "Work email", value: s.field, focused: s.status < 2, status: s.status == 1 ? .error : s.status == 2 ? .valid : nil)
        States(value: s.on ? "done" : "idle", align: .leading, states: [
          "idle": Text("We'll send a link to confirm it").font(.system(size: 11)).foregroundStyle(look.text),
          "done": Text("Link sent").font(.system(size: 11)).foregroundStyle(look.successText),
        ])
      }
      .padding(20)
      .foregroundStyle(look.textStrong)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      .background(look.surface)
    }
  }
}
