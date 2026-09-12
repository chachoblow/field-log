import XCTest

/// Smoke test for the recording flow: create, apply a preset, tag, edit, relaunch,
/// confirm everything survived, then swipe to delete. Runs against the simulator's
/// real store. Set FIELDLOG_SCREENSHOT_DIR in the scheme's test environment to
/// save screenshots along the way.
final class FieldLogUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testCreateEditRelaunchDelete() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Gear"].tap()
        XCTAssertTrue(app.staticTexts["Zoom F3"].waitForExistence(timeout: 5))
        save(app.screenshot(), as: "gear")
        app.buttons["Done"].tap()

        app.buttons["New Recording"].tap()

        let place = app.textFields["Place"]
        XCTAssertTrue(place.waitForExistence(timeout: 5))
        place.tap()
        place.typeText("UI Test Cove\n")

        app.buttons["Apply Preset"].tap()
        app.buttons["Field kit"].tap()
        XCTAssertTrue(containing("Zoom F3", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(containing("48 kHz", in: app).waitForExistence(timeout: 5))

        let filename = app.textFields["Filename"]
        filename.tap()
        filename.typeText("UITEST01.WAV\n")

        let tagField = app.textFields["Add tag"]
        scroll(app, until: tagField)
        tagField.tap()
        tagField.typeText("uitest\n")
        XCTAssertTrue(app.staticTexts["uitest"].waitForExistence(timeout: 5))
        save(app.screenshot(), as: "form")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["UI Test Cove"].waitForExistence(timeout: 5))
        save(app.screenshot(), as: "list")

        app.terminate()
        app.launch()

        let row = app.staticTexts["UI Test Cove"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertEqual(app.textFields["Filename"].value as? String, "UITEST01.WAV")
        XCTAssertTrue(containing("Zoom F3", in: app).exists)
        scroll(app, until: app.staticTexts["uitest"])
        XCTAssertTrue(app.staticTexts["uitest"].exists)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        row.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["No Recordings"].waitForExistence(timeout: 5))
    }

    private func containing(_ text: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", text, text))
            .firstMatch
    }

    /// Form rows are created lazily, so an element below the fold does not exist until scrolled in.
    private func scroll(_ app: XCUIApplication, until element: XCUIElement) {
        for _ in 0..<6 where !element.exists {
            app.swipeUp()
        }
    }

    private func save(_ screenshot: XCUIScreenshot, as name: String) {
        guard let dir = ProcessInfo.processInfo.environment["FIELDLOG_SCREENSHOT_DIR"] else { return }
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
