import XCTest

/// Smoke test for the recording flow: create, fill the form top to bottom
/// (mic technique, gear preset, tag, filename, place), wait for the location
/// fix, relaunch, confirm everything survived, then swipe to delete.
///
/// The steps follow the form's section order, because `scroll(_:until:)` only
/// swipes downward and a row below the fold does not exist until it is reached.
/// Runs against the simulator's real store. Before running, grant location access
/// and set a simulated location from the command line (see AGENTS.md); the test
/// cannot do that itself. Set FIELDLOG_SCREENSHOT_DIR in the scheme's test
/// environment to save screenshots along the way.
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

        let micTechnique = app.textFields["Mic technique"]
        XCTAssertTrue(micTechnique.waitForExistence(timeout: 5))
        micTechnique.tap()
        micTechnique.typeText("ORTF\n")

        let applyPreset = app.buttons["Apply Preset"]
        scroll(app, until: applyPreset)
        applyPreset.tap()
        app.buttons["Field kit"].tap()
        XCTAssertTrue(containing("Zoom F3", in: app).waitForExistence(timeout: 5))

        let tagField = app.textFields["Add tag"]
        scroll(app, until: tagField)
        tagField.tap()
        tagField.typeText("uitest\n")
        XCTAssertTrue(app.staticTexts["uitest"].waitForExistence(timeout: 5))

        let filename = app.textFields["Filename"]
        scroll(app, until: filename)
        filename.tap()
        filename.typeText("UITEST01.WAV\n")

        // The recorder's defaults fill the rows below the filename, so they need
        // their own scroll rather than riding along with it.
        let sampleRate = containing("48 kHz", in: app)
        scroll(app, until: sampleRate)
        XCTAssertTrue(sampleRate.waitForExistence(timeout: 5))

        let place = app.textFields["Place"]
        scroll(app, until: place)
        XCTAssertTrue(app.staticTexts["Coordinates"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["Locating…"].waitForNonExistence(timeout: 30))
        save(app.screenshot(), as: "where")
        clearAndType("UI Test Cove\n", into: place)
        save(app.screenshot(), as: "form")

        let updateWeather = app.buttons["Update Weather"]
        scroll(app, until: updateWeather)
        XCTAssertTrue(updateWeather.exists)
        save(app.screenshot(), as: "weather")

        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["UI Test Cove"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["uitest"].exists, "the list row should show the recording's tags")
        save(app.screenshot(), as: "list")

        app.terminate()
        app.launch()

        let row = app.staticTexts["UI Test Cove"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        let savedMic = app.textFields["Mic technique"]
        XCTAssertTrue(savedMic.waitForExistence(timeout: 5))
        XCTAssertEqual(savedMic.value as? String, "ORTF")
        scroll(app, until: containing("Zoom F3", in: app))
        XCTAssertTrue(containing("Zoom F3", in: app).waitForExistence(timeout: 5))
        scroll(app, until: app.staticTexts["uitest"])
        XCTAssertTrue(app.staticTexts["uitest"].exists)
        let savedFilename = app.textFields["Filename"]
        scroll(app, until: savedFilename)
        XCTAssertEqual(savedFilename.value as? String, "UITEST01.WAV")
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

    /// Reverse geocoding may already have filled the field, so put the cursor at the
    /// end, delete whatever is there, then type.
    private func clearAndType(_ text: String, into field: XCUIElement) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        if let existing = field.value as? String, existing != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        field.typeText(text)
    }

    /// Form rows are created lazily, so an element below the fold does not exist until scrolled in.
    private func scroll(_ app: XCUIApplication, until element: XCUIElement) {
        for _ in 0..<10 where !element.exists {
            app.swipeUp()
        }
    }

    private func save(_ screenshot: XCUIScreenshot, as name: String) {
        guard let dir = ProcessInfo.processInfo.environment["FIELDLOG_SCREENSHOT_DIR"] else { return }
        try? screenshot.pngRepresentation.write(to: URL(fileURLWithPath: dir).appendingPathComponent("\(name).png"))
    }
}
