import XCTest
import UIKit

/// Captures App Store screenshots of the real app (Guideline 2.3.3).
/// Lives on the app-store-screenshots branch only. Does not change app behavior.
final class AppStoreScreenshotTests: XCTestCase {
    private var app: XCUIApplication!
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        let path = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"]
            ?? FileManager.default.temporaryDirectory.appendingPathComponent("screens").path
        outputDirectory = URL(fileURLWithPath: path, isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        XCUIDevice.shared.orientation = .portrait
        app = XCUIApplication()
        app.launchArguments = ["-VoiceOverMasteryUITesting", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        settle()
    }

    func testCaptureAppStoreScreenshots() throws {
        let welcome = app.buttons["I use VoiceOver"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 20), "welcome choice")
        try capture("01-welcome")
        welcome.tap()
        settle()

        tab("Browse")
        XCTAssertTrue(app.buttons["part-iphone"].waitForExistence(timeout: 15))
        try capture("02-browse")

        app.buttons["part-iphone"].tap()
        XCTAssertTrue(app.buttons["chapter-1.1"].waitForExistence(timeout: 10))
        try capture("03-iphone-chapters")

        app.buttons["chapter-1.1"].tap()
        XCTAssertTrue(app.staticTexts["chapterTitle"].waitForExistence(timeout: 10))
        try capture("04-chapter")

        tab("Search")
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Screen Curtain")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        dismissKeyboard()
        try capture("05-search")

        tab("Reference")
        let iphone = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "iPhone, quick reference")).firstMatch
        XCTAssertTrue(iphone.waitForExistence(timeout: 10))
        iphone.tap()
        settle()
        try capture("06-quick-reference")

        tab("Practice")
        XCTAssertTrue(app.buttons["practiceButton"].waitForExistence(timeout: 10))
        try capture("07-practice")
    }

    private func capture(_ name: String) throws {
        settle()
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = "\(prefix)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        let url = outputDirectory.appendingPathComponent("\(prefix)-\(name).png")
        try shot.pngRepresentation.write(to: url)
        print("Wrote \(url.path)")
    }

    private var prefix: String {
        UIDevice.current.userInterfaceIdiom == .pad ? "ipad" : "iphone"
    }

    private func tab(_ name: String) {
        let bar = app.tabBars.buttons[name]
        if bar.waitForExistence(timeout: 8) {
            bar.tap()
        } else {
            let any = app.buttons.matching(NSPredicate(format: "label == %@", name)).firstMatch
            XCTAssertTrue(any.waitForExistence(timeout: 5), "tab \(name)")
            any.tap()
        }
        settle()
    }

    private func dismissKeyboard() {
        for key in ["Search", "search", "Done", "Return", "return"] where app.keyboards.buttons[key].exists {
            app.keyboards.buttons[key].tap()
            settle()
            return
        }
    }

    private func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))
    }
}
