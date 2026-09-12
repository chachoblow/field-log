import XCTest

/// Smoke test for the recording flow: create, wait for the location fix, apply a
/// preset, add a marker, tag, edit, relaunch, confirm everything survived, then swipe to delete.
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

        let place = app.textFields["Place"]
        XCTAssertTrue(place.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Coordinates"].waitForExistence(timeout: 30))
        XCTAssertTrue(app.staticTexts["Locating…"].waitForNonExistence(timeout: 30))
        save(app.screenshot(), as: "where")
        clearAndType("UI Test Cove\n", into: place)

        let applyPreset = app.buttons["Apply Preset"]
        scroll(app, until: applyPreset)
        applyPreset.tap()
        app.buttons["Field kit"].tap()
        XCTAssertTrue(containing("Zoom F3", in: app).waitForExistence(timeout: 5))

        let filename = app.textFields["Filename"]
        scroll(app, until: filename)
        XCTAssertTrue(containing("48 kHz", in: app).waitForExistence(timeout: 5))
        filename.tap()
        filename.typeText("UITEST01.WAV\n")

        let addMarker = app.buttons["Add Marker"]
        scroll(app, until: addMarker)
        addMarker.tap()
        let note = app.textFields["Note"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertTrue(offsetLabel(in: app).exists)
        note.typeText("plane overhead\n")

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
        scroll(app, until: containing("Zoom F3", in: app))
        XCTAssertTrue(containing("Zoom F3", in: app).waitForExistence(timeout: 5))
        let savedFilename = app.textFields["Filename"]
        scroll(app, until: savedFilename)
        XCTAssertEqual(savedFilename.value as? String, "UITEST01.WAV")
        scroll(app, until: app.textFields["Note"])
        XCTAssertEqual(app.textFields["Note"].value as? String, "plane overhead")
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

    /// Reverse geocoding may already have filled the field, so put the cursor at the
    /// end, delete whatever is there, then type.
    private func clearAndType(_ text: String, into field: XCUIElement) {
        field.coordinate(withNormalizedOffset: CGVector(dx: 0.98, dy: 0.5)).tap()
        if let existing = field.value as? String, existing != field.placeholderValue {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count))
        }
        field.typeText(text)
    }

    /// A marker's offset text, "m:ss".
    private func offsetLabel(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "^\\d+:\\d\\d$")).firstMatch
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
