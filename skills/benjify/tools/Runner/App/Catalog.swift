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
    Entry(name: "lab-soak", view: AnyView(SoakLab())),
    Entry(name: "lab-canary", view: AnyView(CheckerCanary())),
    Entry(name: "lab-state-canary", view: AnyView(StateCanary())),
    Entry(name: "payout-flow", view: AnyView(PayoutFlow())),
    Entry(name: "payout-flow-labeled", view: AnyView(PayoutFlow(accessibilityLabel: "A $12,400 payout sent instantly to Chase, arriving in about 30 minutes"))),
    Entry(name: "parts", view: AnyView(PartsSpecimen())),
    Entry(name: "form-error", view: AnyView(FormError())),
    Entry(name: "form-error-labeled", view: AnyView(FormError(accessibilityLabel: "A sign-up form catches a missing email domain, then creates the account"))),
  ]

  static func entry(_ name: String) -> Entry? { entries.first { $0.name == name } }
}
