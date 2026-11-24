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
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let welcome = app.buttons["audienceVoiceOver"]
        XCTAssertTrue(welcome.waitForExistence(timeout: 20), "welcome choice")
        try capture("01-welcome")
        chooseVoiceOver()
        if isPad {
            XCUIDevice.shared.orientation = .landscapeLeft
            settle()
        }

        tab("Browse")
        XCTAssertTrue(el("part-iphone").waitForExistence(timeout: 15), "part-iphone")
        try capture("02-browse")

        if !el("chapter-1.1").waitForExistence(timeout: 3) {
            el("part-iphone").tap()
            settle()
        }
        XCTAssertTrue(el("chapter-1.1").waitForExistence(timeout: 10), "chapter-1.1")
        if !isPad { try capture("03-iphone-chapters") }

        el("chapter-1.1").tap()
        XCTAssertTrue(app.staticTexts["chapterTitle"].waitForExistence(timeout: 10))
        try capture(isPad ? "03-chapter" : "04-chapter")

        tab("Search")
        let field = app.textFields["searchField"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Screen Curtain")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        dismissKeyboard()
        try capture(isPad ? "04-search" : "05-search")

        tab("Reference")
        let iphone = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "iPhone, quick reference")).firstMatch
        XCTAssertTrue(iphone.waitForExistence(timeout: 10))
        iphone.tap()
        settle()
        try capture(isPad ? "05-quick-reference" : "06-quick-reference")

        tab("Practice")
        XCTAssertTrue(app.buttons["practiceButton"].waitForExistence(timeout: 10))
        try capture(isPad ? "06-practice" : "07-practice")
    }

    private func el(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func chooseVoiceOver() {
        let welcome = app.buttons["audienceVoiceOver"]
        for attempt in 0..<4 where welcome.exists {
            switch attempt {
            case 0: welcome.tap()
            case 1: app.staticTexts["I use VoiceOver"].firstMatch.tap()
            default: welcome.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            }
            settle()
            if !welcome.waitForExistence(timeout: 2) { break }
        }
        XCTAssertFalse(welcome.exists, "welcome dismissed")
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
