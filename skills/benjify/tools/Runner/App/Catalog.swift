import SwiftUI

// Every scene the runner can show by name. The examples live in
// skills/benjify/examples; the specimens and labs live here.
@MainActor
struct Catalog {
  struct Entry {
    let name: String
    let view: AnyView
  }

  static let entries: [Entry] = [
    Entry(name: "hello", view: AnyView(HelloScene())),
    Entry(name: "lab-sweep", view: AnyView(SweepLab())),
  ]

  static func entry(_ name: String) -> Entry? { entries.first { $0.name == name } }
}
