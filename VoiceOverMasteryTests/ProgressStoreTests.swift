import XCTest
#if canImport(VoiceOverMasteryMac)
@testable import VoiceOverMasteryMac
#else
@testable import VoiceOverMastery
#endif

final class ProgressStoreTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "VoiceOverMasteryTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testCompleteAndBookmarkPersist() {
        let progress = ProgressStore(defaults: defaults)
        progress.toggleComplete("1.1")
        progress.toggleComplete("1.3")
        progress.toggleComplete("1.1")
        XCTAssertFalse(progress.isComplete("1.1"))
        XCTAssertTrue(progress.isComplete("1.3"))
        progress.toggleBookmark("1.8")
        progress.toggleBookmark("1.3")
        XCTAssertEqual(progress.bookmarkIDs, ["1.3", "1.8"])
        let reloaded = ProgressStore(defaults: defaults)
        XCTAssertEqual(reloaded.completedIDs, ["1.3"])
        XCTAssertEqual(reloaded.bookmarkIDs, ["1.3", "1.8"])
        reloaded.removeBookmark("1.3")
        XCTAssertEqual(ProgressStore(defaults: defaults).bookmarkIDs, ["1.8"])
        reloaded.clearCompleted()
        reloaded.clearBookmarks()
        XCTAssertTrue(ProgressStore(defaults: defaults).completedIDs.isEmpty)
        XCTAssertTrue(ProgressStore(defaults: defaults).bookmarkIDs.isEmpty)
    }

    func testResumeRemembersChapterAndSection() {
        let progress = ProgressStore(defaults: defaults)
        progress.noteOpened("1.3")
        XCTAssertEqual(progress.lastChapterID, "1.3")
        XCTAssertNil(progress.lastSectionID)
        progress.noteSection("1.3", "quick-reference")
        progress.noteOpened("1.3")
        XCTAssertEqual(progress.lastSectionID, "quick-reference", "reopening the same chapter keeps the section")
        progress.noteOpened("2.1")
        XCTAssertEqual(progress.lastChapterID, "2.1")
        XCTAssertNil(progress.lastSectionID, "a different chapter clears the section")
        XCTAssertEqual(ProgressStore(defaults: defaults).lastChapterID, "2.1")
        progress.clearResume()
        XCTAssertNil(ProgressStore(defaults: defaults).lastChapterID)
    }

    func testAudienceGate() {
        let progress = ProgressStore(defaults: defaults)
        XCTAssertNil(progress.audience)
        XCTAssertFalse(progress.orientationComplete)
        progress.choose(.voiceOver)
        XCTAssertEqual(progress.audience, .voiceOver)
        XCTAssertTrue(progress.orientationComplete)
        progress.clearAudience()
        XCTAssertNil(ProgressStore(defaults: defaults).audience)
        let sighted = ProgressStore(defaults: defaults)
        sighted.choose(.sighted)
        XCTAssertEqual(sighted.audience, .sighted)
        XCTAssertFalse(sighted.orientationComplete)
        sighted.completeOrientation()
        XCTAssertTrue(ProgressStore(defaults: defaults).orientationComplete)
    }
}
