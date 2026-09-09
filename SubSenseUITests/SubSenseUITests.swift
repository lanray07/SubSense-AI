import XCTest
import StoreKitTest

final class SubSenseUITests: XCTestCase {
    @MainActor private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }
    @MainActor private func storeSession() throws -> SKTestSession {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("SubSense/Resources/SubSense.storekit")
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState(); session.clearTransactions(); session.disableDialogs = true; session.storefront = "GBR"
        return session
    }
    @MainActor func testFreshInstallPersistenceAndEdit() throws {
        continueAfterFailure = false
        let session = try storeSession(); defer { session.resetToDefaultState() }
        let app = XCUIApplication(); app.launchArguments = ["--uitesting-reset"]; app.launch()
        XCTAssertTrue(app.buttons["Get Started"].waitForExistence(timeout: 20))
        capture("onboarding-light", app)
        app.buttons["Get Started"].tap()
        for _ in 0..<3 { app.buttons["Next"].tap() }
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.buttons["Add My First Subscription"].waitForExistence(timeout: 5))
        app.buttons["Add My First Subscription"].tap()
        XCTAssertTrue(app.textFields["Subscription name"].waitForExistence(timeout: 5))
        app.textFields["Subscription name"].tap(); app.textFields["Subscription name"].typeText("Persistent membership")
        app.textFields["Price per billing period"].tap(); app.textFields["Price per billing period"].typeText("12.50")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.buttons["Subscriptions"].firstMatch.waitForExistence(timeout: 5))
        app.terminate(); app.launchArguments = []; app.launch()
        XCTAssertTrue(app.buttons["Subscriptions"].firstMatch.waitForExistence(timeout: 20))
        app.buttons["Subscriptions"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Persistent membership"].firstMatch.waitForExistence(timeout: 5))
        app.staticTexts["Persistent membership"].firstMatch.tap()
        app.buttons["Edit"].tap()
        let field = app.textFields["Subscription name"]
        XCTAssertTrue(field.waitForExistence(timeout: 5)); field.tap()
        // Replace through the hardware keyboard to exercise the real editor.
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Persistent membership".count))
        field.typeText("Edited membership")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Edited membership"].firstMatch.waitForExistence(timeout: 5))
        capture("saved-subscription", app)
        app.terminate(); app.launch()
        app.buttons["Subscriptions"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Edited membership"].firstMatch.waitForExistence(timeout: 5))
    }
    @MainActor func testPurchaseRestoreAndExpiration() async throws {
        continueAfterFailure = false
        let session = try storeSession(); defer { session.resetToDefaultState(); session.clearTransactions() }
        let app = XCUIApplication(); app.launchArguments = ["--demo"]; app.launch()
        XCTAssertTrue(app.buttons["Settings"].firstMatch.waitForExistence(timeout: 20))
        app.buttons["Settings"].firstMatch.tap(); app.buttons["Discover SubSense Pro"].tap()
        let monthly = app.buttons["com.subsense.pro.monthly"]
        XCTAssertTrue(monthly.waitForExistence(timeout: 20)); reveal(monthly, in: app); monthly.tap()
        let subscribe = app.buttons["subscribe-selected-plan"]; reveal(subscribe, in: app); subscribe.tap()
        XCTAssertTrue(app.staticTexts["Your Pro access is active"].waitForExistence(timeout: 20))
        let restore = app.buttons["Restore Purchases"]; reveal(restore, in: app); restore.tap()
        XCTAssertTrue(app.staticTexts["Pro purchases restored."].waitForExistence(timeout: 20))
        capture("purchase-restored", app)
        try session.expireSubscription(productIdentifier: "com.subsense.pro.monthly")
        app.terminate(); app.launch()
        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Discover SubSense Pro"].waitForExistence(timeout: 20))
        _ = try await session.buyProduct(identifier: "com.subsense.pro.annual", options: [])
        XCTAssertTrue(app.buttons["Manage SubSense Pro"].waitForExistence(timeout: 20))
        let transaction = try XCTUnwrap(session.allTransactions().last(where: { $0.productIdentifier == "com.subsense.pro.annual" }))
        try session.refundTransaction(identifier: transaction.identifier)
        XCTAssertTrue(app.buttons["Discover SubSense Pro"].waitForExistence(timeout: 20))
    }
    @MainActor func testFreeSubscriptionLimit() throws {
        continueAfterFailure = false
        let session = try storeSession(); defer { session.resetToDefaultState() }
        let app = XCUIApplication(); app.launchArguments = ["--uitesting-reset", "-onboardingComplete", "YES"]; app.launch()
        XCTAssertTrue(app.buttons["Subscriptions"].firstMatch.waitForExistence(timeout: 20)); app.buttons["Subscriptions"].firstMatch.tap()
        for number in 1...6 {
            app.buttons["Add subscription"].tap()
            XCTAssertTrue(app.textFields["Subscription name"].waitForExistence(timeout: 5))
            app.textFields["Subscription name"].tap(); app.textFields["Subscription name"].typeText("Membership \(number)")
            app.textFields["Price per billing period"].tap(); app.textFields["Price per billing period"].typeText("5")
            app.buttons["Save"].tap()
            if number <= 5 { XCTAssertTrue(app.navigationBars["Subscriptions"].waitForExistence(timeout: 5)) }
        }
        XCTAssertTrue(app.alerts.staticTexts["Free supports five subscriptions. Upgrade to Pro to add more."].waitForExistence(timeout: 5))
        capture("free-limit", app)
        app.alerts.buttons["OK"].tap(); app.buttons["Cancel"].tap()
        XCTAssertFalse(app.staticTexts["Membership 6"].exists)
    }
    @MainActor func testReceiptReviewAndExport() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--demo"]; app.launch()
        XCTAssertTrue(app.buttons["Settings"].firstMatch.waitForExistence(timeout: 20))
        app.buttons["Settings"].firstMatch.tap(); app.buttons["Import a receipt"].tap()
        let receipt = app.textViews["Receipt text"]
        XCTAssertTrue(receipt.waitForExistence(timeout: 5)); receipt.tap(); receipt.typeText("Example membership\nGBP 19.99\nBilled monthly")
        let extract = app.buttons["Extract subscription"]; reveal(extract, in: app); extract.tap()
        let review = app.buttons["Review & edit extracted details"]
        XCTAssertTrue(review.waitForExistence(timeout: 10)); reveal(review, in: app); review.tap()
        XCTAssertTrue(app.textFields["Subscription name"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap(); app.buttons["Done"].tap()
        app.buttons["Export reports"].tap()
        XCTAssertTrue(app.buttons["Prepare export"].waitForExistence(timeout: 5))
        app.buttons["Prepare export"].tap()
        XCTAssertTrue(app.buttons["Share or save report"].waitForExistence(timeout: 10))
        capture("export-ready", app)
    }
    @MainActor func testDarkModeLargeTextAndLandscape() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--uitesting-dark", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 20))
        capture("accessibility-home-dark", app)
        app.buttons["Settings"].firstMatch.tap()
        let privacy = app.buttons["How your data is handled"]; reveal(privacy, in: app); privacy.tap()
        XCTAssertTrue(app.navigationBars["Your data stays yours"].waitForExistence(timeout: 5))
        capture("accessibility-privacy-dark", app)
        app.buttons["Done"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        let rotated = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in app.frame.width > app.frame.height }, object: app)
        XCTAssertEqual(XCTWaiter.wait(for: [rotated], timeout: 10), .completed)
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 5)); app.buttons["Home"].firstMatch.tap()
        capture("accessibility-landscape-dark", app)
    }
    @MainActor func testExpandedStoreScreenshotSet() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 20))
        capture("store-01-home", app)
        app.buttons["Subscriptions"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Subscriptions"].waitForExistence(timeout: 5))
        capture("store-02-subscriptions", app)
        app.buttons["Insights"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        capture("store-03-insights", app)
        app.buttons["Copilot"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Where can I save money?"].waitForExistence(timeout: 5))
        app.buttons["Where can I save money?"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Start by reviewing'")).firstMatch.waitForExistence(timeout: 10))
        capture("store-04-copilot", app)
        if app.frame.width > 700 {
            app.buttons["Subscriptions"].firstMatch.tap()
            app.staticTexts["ChatGPT Plus"].firstMatch.tap()
            XCTAssertTrue(app.staticTexts["Value Score"].firstMatch.waitForExistence(timeout: 5))
            capture("store-05-detail", app)
            app.buttons["Settings"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
            capture("store-06-settings", app)
            app.buttons["Profile & savings goal"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Profile & goals"].waitForExistence(timeout: 5))
            capture("store-07-goals", app)
            app.navigationBars.buttons["Settings"].firstMatch.tap()
            app.buttons["Renewal reminders"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Renewal reminders"].waitForExistence(timeout: 5))
            capture("store-08-reminders", app)
            return
        }
        app.buttons["Home"].firstMatch.tap()
        for (label, title, name) in [
            ("Upcoming charges", "Renewal Calendar", "store-05-renewals"),
            ("Potential savings", "Savings Simulator", "store-06-simulator"),
            ("Subscription health", "Subscription Health Score", "store-07-health")
        ] {
            let button = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", label)).firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            app.staticTexts[label].firstMatch.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            if name == "store-06-simulator" {
                XCTAssertTrue(app.switches.firstMatch.waitForExistence(timeout: 5))
                app.switches.firstMatch.switches.firstMatch.tap()
                XCTAssertTrue(app.staticTexts["Monthly savings"].waitForExistence(timeout: 5))
            }
            capture(name, app)
            app.buttons["Done"].firstMatch.tap()
        }
        app.buttons["Settings"].firstMatch.tap()
        app.buttons["How your data is handled"].tap()
        XCTAssertTrue(app.navigationBars["Your data stays yours"].waitForExistence(timeout: 5))
        capture("store-08-privacy", app)
    }
    @MainActor func testAppStoreScreenshotSet() throws {
        continueAfterFailure = false
        let configurationURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("SubSense/Resources/SubSense.storekit")
        let storeSession = try SKTestSession(contentsOf: configurationURL)
        storeSession.resetToDefaultState()
        storeSession.clearTransactions()
        storeSession.disableDialogs = true
        storeSession.storefront = "GBR"
        defer { storeSession.resetToDefaultState() }
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 20))
        capture("store-01-home", app)
        app.buttons["Subscriptions"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Subscriptions"].waitForExistence(timeout: 5))
        capture("store-02-subscriptions", app)
        app.buttons["Insights"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        capture("store-03-insights", app)
        app.buttons["Copilot"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Where can I save money?"].waitForExistence(timeout: 5))
        app.buttons["Where can I save money?"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Start by reviewing'")).firstMatch.waitForExistence(timeout: 10))
        capture("store-04-copilot", app)
        app.buttons["Settings"].firstMatch.tap()
        app.buttons["Discover SubSense Pro"].tap()
        XCTAssertTrue(app.navigationBars["SubSense Pro"].waitForExistence(timeout: 5))
        if app.buttons["Retry loading plans"].waitForExistence(timeout: 5) {
            app.buttons["Retry loading plans"].tap()
        }
        XCTAssertTrue(app.buttons.containing(NSPredicate(format: "label CONTAINS '1.49'")).firstMatch.waitForExistence(timeout: 20))
        capture("review-pro-features", app)
        app.swipeUp()
        capture("review-pro-purchase", app)
    }
    @MainActor func testDemoNavigationAndScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        capture("01-dashboard", app)
        app.buttons["Subscriptions"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Subscriptions"].waitForExistence(timeout: 5))
        capture("02-subscriptions", app)
        app.buttons["Insights"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        capture("03-insights", app)
        app.buttons["Copilot"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Where can I save money?"].waitForExistence(timeout: 5))
        app.buttons["Where can I save money?"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Start by reviewing'")).firstMatch.waitForExistence(timeout: 5))
        capture("04-copilot", app)
        app.buttons["Settings"].firstMatch.tap()
        XCTAssertTrue(app.buttons["How your data is handled"].waitForExistence(timeout: 5))
    }
    @MainActor func testAddSubscriptionValidationAndPersistenceWithinDemo() {
        let app = XCUIApplication(); app.launchArguments = ["--demo"]; app.launch()
        app.buttons["Subscriptions"].firstMatch.tap()
        app.buttons["Add subscription"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Enter a valid price."].waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        let name = app.textFields["Subscription name"]; name.tap(); name.typeText("Test membership")
        let price = app.textFields["Price per billing period"]; price.tap(); price.typeText("12.50")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.navigationBars["Subscriptions"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch
        search.tap(); search.typeText("Test membership")
        XCTAssertTrue(app.staticTexts["Test membership"].waitForExistence(timeout: 5))
    }
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testCalendarNavigation() {
        continueAfterFailure = false
        let app = XCUIApplication(); app.launchArguments = ["--demo"]; app.launch()
        XCTAssertTrue(app.staticTexts["Upcoming charges"].waitForExistence(timeout: 20))
        app.staticTexts["Upcoming charges"].tap()
        XCTAssertTrue(app.navigationBars["Renewal Calendar"].waitForExistence(timeout: 10))
        app.buttons["Next month"].tap()
        app.buttons["Previous month"].tap()
        app.buttons["Timeline"].tap()
        app.buttons["Upcoming"].tap()
        capture("calendar-validated", app)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["Upcoming charges"].waitForExistence(timeout: 5))
    }
}
