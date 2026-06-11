import XCTest

/// The single most important journey in the app: a child taps word tiles, sees them collect in the
/// message bar, and speaks the sentence. If this breaks, the app is not a communication device.
final class KidModeUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        // iPads are used in landscape for AAC (mounted on wheelchairs/stands) — test that posture.
        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }
        app = XCUIApplication()
        app.launchArguments = ["--uitest"]
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    /// The message bar surfaces as a ScrollView, and chips as collapsed "Other" elements — query both
    /// by identifier across any element type rather than assuming a fixed type.
    private var messageBar: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "messageBar").firstMatch
    }

    private func chips(_ label: String) -> XCUIElementQuery {
        messageBar.descendants(matching: .any).matching(identifier: "chip_\(label)")
    }

    func testBuildMessageSpeakAndClear() {
        // "want" and "go" are early core starter words, reliably on the first home page at any
        // screen size (later core words like "more" can paginate onto a second fringe page).
        let wantTile = app.buttons["tile_want"]
        let goTile = app.buttons["tile_go"]
        XCTAssertTrue(wantTile.waitForExistence(timeout: 10), "Core word tile 'want' should be on the home board")
        XCTAssertTrue(goTile.exists, "Core word tile 'go' should be on the home board")

        let speak = app.buttons["speakButton"]
        let delete = app.buttons["deleteButton"]
        let clear = app.buttons["clearButton"]
        XCTAssertFalse(speak.isEnabled, "Speak is disabled while the message is empty")
        XCTAssertFalse(delete.isEnabled, "Delete is disabled while the message is empty")

        wantTile.tap()
        goTile.tap()

        XCTAssertTrue(chips("want").firstMatch.waitForExistence(timeout: 5), "Tapped word appears in the message bar")
        XCTAssertTrue(chips("go").firstMatch.exists, "Second tapped word appears in the message bar")
        XCTAssertTrue(speak.isEnabled, "Speak enables once the message has words")

        speak.tap()

        // Delete removes only the most recent word.
        delete.tap()
        XCTAssertFalse(chips("go").firstMatch.exists, "Delete removes the last word")
        XCTAssertTrue(chips("want").firstMatch.exists, "Earlier words survive Delete")

        // Clear empties the message and the controls disable again.
        clear.tap()
        XCTAssertFalse(chips("want").firstMatch.exists, "Clear empties the message bar")
        XCTAssertFalse(speak.isEnabled, "Speak disables again once the message is empty")
    }

    func testSameWordCanBeTappedTwice() {
        let wantTile = app.buttons["tile_want"]
        XCTAssertTrue(wantTile.waitForExistence(timeout: 10))

        wantTile.tap()
        wantTile.tap()

        XCTAssertEqual(chips("want").count, 2, "Tapping the same word twice shows two chips ('want want')")
    }
}
