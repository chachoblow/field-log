import XCTest

/// Smoke test for step 2: create a recording, edit it, relaunch, confirm the
/// edits survived, then swipe to delete. Runs against the simulator's real store.
final class FieldLogUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreateEditRelaunchDelete() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["New Recording"].tap()

        let place = app.textFields["Place"]
        XCTAssertTrue(place.waitForExistence(timeout: 5))
        place.tap()
        place.typeText("UI Test Cove")

        let filename = app.textFields["Filename"]
        filename.tap()
        filename.typeText("UITEST01.WAV")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["UI Test Cove"].waitForExistence(timeout: 5))

        app.terminate()
        app.launch()

        let row = app.staticTexts["UI Test Cove"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertEqual(app.textFields["Filename"].value as? String, "UITEST01.WAV")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["No Recordings"].waitForExistence(timeout: 5))
    }
}
