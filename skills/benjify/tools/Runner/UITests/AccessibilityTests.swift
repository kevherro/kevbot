import XCTest

// What VoiceOver gets from a scene, and Apple's accessibility audit on a
// host app showing each gold example.
@MainActor
final class AccessibilityTests: XCTestCase {
  override func setUp() async throws { continueAfterFailure = false }

  func launch(_ scene: String) -> XCUIApplication {
    let app = XCUIApplication()
    app.launchArguments = ["-scene", scene]
    app.launch()
    sleep(2)
    return app
  }

  // A decorative scene (no label) is hidden: none of its words reach VoiceOver.
  func testDecorativeSceneIsHidden() {
    let app = launch("payout-flow")
    XCTAssertFalse(app.staticTexts["Available balance"].exists)
    XCTAssertFalse(app.staticTexts["Instant payout"].exists)
    XCTAssertEqual(app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] 'payout'")).count, 0)
  }

  // A labeled scene is one image element with that label, nothing inside it.
  func testLabeledSceneIsOneImage() {
    let app = launch("payout-flow-labeled")
    let image = app.images["A $12,400 payout sent instantly to Chase, arriving in about 30 minutes"]
    XCTAssertTrue(image.waitForExistence(timeout: 2))
    XCTAssertEqual(image.descendants(matching: .any).count, 0)
    XCTAssertFalse(app.staticTexts["Available balance"].exists)
  }

  func testAuditPayoutFlow() throws { try launch("payout-flow-labeled").performAccessibilityAudit() }
  // A decorative scene is hidden on purpose, so the audit's guess that its
  // drawn words are "potentially inaccessible text" is the design, not a
  // fault. Only that issue is set aside, and it is counted; any other fails.
  func testAuditPayoutFlowDecorative() throws {
    var setAside = 0
    try launch("payout-flow").performAccessibilityAudit { issue in
      guard issue.compactDescription == "Potentially inaccessible text" else { return false }
      setAside += 1
      return true
    }
    print("MEASURE a11y.decorativeSetAside \(setAside)")
  }
  func testAuditFormError() throws { try launch("form-error").performAccessibilityAudit() }
  func testAuditFormErrorLabeled() throws { try launch("form-error-labeled").performAccessibilityAudit() }
}
