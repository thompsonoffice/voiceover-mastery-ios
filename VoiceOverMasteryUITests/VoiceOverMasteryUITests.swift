import XCTest

/// End-to-end checks plus XCUIApplication.performAccessibilityAudit (iOS 17+).
/// These run in the iOS Simulator. They do not replace testing with VoiceOver on a device.
final class VoiceOverMasteryUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-VoiceOverMasteryUITesting"]
        app.launch()
    }

    private func chooseVoiceOverUser() {
        let button = app.buttons["I use VoiceOver"]
        XCTAssertTrue(button.waitForExistence(timeout: 15), "welcome choice")
        button.tap()
        XCTAssertTrue(app.tabBars.buttons["Browse"].waitForExistence(timeout: 10))
    }

    private func tab(_ name: String) {
        let button = app.tabBars.buttons[name]
        XCTAssertTrue(button.waitForExistence(timeout: 10), "tab \(name)")
        button.tap()
    }

    private func openGettingStarted() {
        let part = app.buttons["part-iphone"]
        XCTAssertTrue(part.waitForExistence(timeout: 10))
        part.tap()
        let chapter = app.buttons["chapter-1.1"]
        XCTAssertTrue(chapter.waitForExistence(timeout: 10))
        chapter.tap()
        XCTAssertTrue(app.staticTexts["chapterTitle"].waitForExistence(timeout: 10))
    }

    private func goBack() {
        let back = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        back.tap()
    }

    private func audit(_ screen: String, file: StaticString = #filePath, line: UInt = #line) {
        do {
            try app.performAccessibilityAudit { issue in
                print("Accessibility audit, \(screen): \(issue.auditType) \(issue.compactDescription) element: \(issue.element?.label ?? "")")
                return false
            }
        } catch {
            XCTFail("Audit on \(screen) could not run: \(error)", file: file, line: line)
        }
    }

    func testFiveTabsAreLabeled() {
        chooseVoiceOverUser()
        for name in ["Browse", "Search", "Reference", "Practice", "More"] {
            XCTAssertTrue(app.tabBars.buttons[name].exists, name)
        }
    }

    func testSightedOrientationThenGuide() {
        let sighted = app.buttons["I'm sighted and learning VoiceOver"]
        XCTAssertTrue(sighted.waitForExistence(timeout: 15))
        sighted.tap()
        XCTAssertTrue(app.staticTexts["orientationTitle"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Screen Curtain"].exists)
        XCTAssertTrue(app.staticTexts["Gestures change while VoiceOver is on"].exists)
        XCTAssertTrue(app.staticTexts["Turn VoiceOver on and off safely"].exists)
        let framing = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "not a chapter")).firstMatch
        XCTAssertTrue(framing.exists)
        let shortcut = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "triple-click the side button")).firstMatch
        XCTAssertTrue(shortcut.exists)
        audit("Sighted orientation")
        app.buttons["orientationContinue"].tap()
        XCTAssertTrue(app.tabBars.buttons["Browse"].waitForExistence(timeout: 10))
    }

    func testChapterHeadingsMarkCompleteAndResume() {
        chooseVoiceOverUser()
        openGettingStarted()
        for heading in ["Overview", "What you'll learn", "Practice exercise", "Quick reference summary", "Sources"] {
            XCTAssertTrue(app.staticTexts[heading].exists, heading)
        }
        let mark = app.buttons["markComplete"]
        XCTAssertTrue(mark.waitForExistence(timeout: 5))
        if !mark.isHittable {
            app.swipeUp()
        }
        mark.tap()
        let selected = NSPredicate(format: "isSelected == true")
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: selected, object: app.buttons["markComplete"])], timeout: 5), .completed)
        app.buttons["bookmarkChapter"].tap()
        XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: selected, object: app.buttons["bookmarkChapter"])], timeout: 5), .completed)
        let jump = app.buttons["jump-practice-exercise"]
        var swipes = 0
        while !(jump.exists && jump.isHittable) && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(jump.isHittable)
        jump.tap()
        goBack()
        goBack()
        let resume = app.buttons["resume"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        XCTAssertTrue(resume.label.contains("1.1"))
        XCTAssertTrue(resume.label.contains("Practice exercise"))
        tab("More")
        app.buttons["moreBookmarks"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Getting Started with VoiceOver on iPhone")).firstMatch.waitForExistence(timeout: 10))
    }

    func testSearchFindsScreenCurtain() {
        chooseVoiceOverUser()
        tab("Search")
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText("Screen Curtain")
        XCTAssertTrue(app.staticTexts["resultCount"].waitForExistence(timeout: 10))
        let hit = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "1.6")).firstMatch
        XCTAssertTrue(hit.waitForExistence(timeout: 10))
    }

    func testQuickReferenceUsesChapterLines() {
        chooseVoiceOverUser()
        tab("Reference")
        let iphone = app.buttons["quick-iphone"]
        XCTAssertTrue(iphone.waitForExistence(timeout: 10))
        iphone.tap()
        let line = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "VoiceOver speaks the item under your finger")).firstMatch
        var swipes = 0
        while !line.exists && swipes < 4 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(line.exists)
    }

    func testPracticeControls() {
        chooseVoiceOverUser()
        tab("Practice")
        let button = app.buttons["practiceButton"]
        XCTAssertTrue(button.waitForExistence(timeout: 10))
        XCTAssertTrue(app.sliders["practiceSlider"].exists)
        let apples = app.buttons["Apples"]
        var swipes = 0
        while !apples.exists && swipes < 6 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(apples.exists, "Practice list row Apples")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "does not add VoiceOver gestures")).firstMatch.exists)
        button.tap()
        let status = app.staticTexts["practiceStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 5))
        XCTAssertTrue(status.label.contains("Sample button activated"))
    }

    func testSettingsTextSize() {
        chooseVoiceOverUser()
        tab("More")
        app.buttons["moreSettings"].tap()
        let textSize = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Text size")).firstMatch
        XCTAssertTrue(textSize.waitForExistence(timeout: 10))
        textSize.tap()
        let size = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Accessibility size 3")).firstMatch
        XCTAssertTrue(size.waitForExistence(timeout: 10))
        size.tap()
        tab("Browse")
        XCTAssertTrue(app.buttons["part-iphone"].waitForExistence(timeout: 10))
    }

    func testAccessibilityAuditMainScreens() {
        audit("Welcome")
        chooseVoiceOverUser()
        audit("Browse")
        tab("Search")
        audit("Search")
        tab("Reference")
        audit("Reference")
        tab("Practice")
        audit("Practice home")
        tab("More")
        audit("More")
        app.buttons["moreSettings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        audit("Settings")
        goBack()
        app.buttons["moreAbout"].tap()
        XCTAssertTrue(app.staticTexts["About VoiceOver Mastery"].waitForExistence(timeout: 10))
        audit("About")
        goBack()
        app.buttons["morePrivacy"].tap()
        XCTAssertTrue(app.staticTexts["VoiceOver Mastery Privacy Policy"].waitForExistence(timeout: 10))
        audit("Privacy Policy")
        goBack()
        app.buttons["moreOrientation"].tap()
        XCTAssertTrue(app.staticTexts["orientationTitle"].waitForExistence(timeout: 10))
        audit("Orientation from More")
        goBack()
        tab("Browse")
        openGettingStarted()
        audit("Chapter")
    }
}
