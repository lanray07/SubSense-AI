import XCTest

final class SubSenseUITests: XCTestCase {
    @MainActor func testDemoNavigationAndScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        capture("01-dashboard", app)
        app.tabBars.buttons["Subscriptions"].tap()
        XCTAssertTrue(app.navigationBars["Subscriptions"].waitForExistence(timeout: 5))
        capture("02-subscriptions", app)
        app.tabBars.buttons["Insights"].tap()
        XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 5))
        capture("03-insights", app)
        app.tabBars.buttons["Copilot"].tap()
        XCTAssertTrue(app.buttons["Where can I save money?"].waitForExistence(timeout: 5))
        app.buttons["Where can I save money?"].tap()
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Start by reviewing'")).firstMatch.waitForExistence(timeout: 5))
        capture("04-copilot", app)
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.buttons["How your data is handled"].waitForExistence(timeout: 5))
    }
    @MainActor func testAddSubscriptionValidationAndPersistenceWithinDemo() {
        let app = XCUIApplication(); app.launchArguments = ["--demo"]; app.launch()
        app.tabBars.buttons["Subscriptions"].tap()
        app.buttons["Add subscription"].tap()
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Enter a valid price."].waitForExistence(timeout: 5))
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
}
