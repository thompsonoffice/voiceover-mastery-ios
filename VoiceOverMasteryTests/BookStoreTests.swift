import XCTest
@testable import VoiceOverMastery

final class BookStoreTests: XCTestCase {
    private static let shared: Book = {
        let bundle = Bundle(for: ProgressStore.self)
        return try! BookLoader.loadBundled(bundle: bundle)
    }()

    private var book: Book { Self.shared }

    private func words(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }

    func testBundledGuideHas54Chapters() {
        XCTAssertEqual(book.title, "VoiceOver Mastery")
        XCTAssertEqual(book.chapterCount, 54)
        XCTAssertEqual(book.chapters.count, 54)
        XCTAssertEqual(book.parts.map(\.id), ["about", "iphone", "ipad", "mac", "watch", "tv", "vision", "apps"])
        XCTAssertEqual(book.devices.map(\.platform), ["iPhone", "iPad", "Mac", "Apple Watch", "Apple TV", "Apple Vision Pro"])
        XCTAssertEqual(book.part("iphone")?.chapters.count, 25)
        XCTAssertEqual(book.part("ipad")?.chapters.count, 5)
        XCTAssertEqual(book.part("mac")?.chapters.count, 9)
        XCTAssertEqual(book.part("watch")?.chapters.count, 4)
        XCTAssertEqual(book.part("tv")?.chapters.count, 3)
        XCTAssertEqual(book.part("vision")?.chapters.count, 3)
        XCTAssertEqual(book.part("apps")?.chapters.count, 3)
        XCTAssertEqual(book.part("about")?.chapters.count, 2)
        XCTAssertGreaterThan(book.wordCount, 45000)
        XCTAssertEqual(book.index.count, 92)
    }

    func testChapterIDsAreUniqueAndTitledFromTheBook() throws {
        XCTAssertEqual(Set(book.chapters.map(\.id)).count, book.chapters.count)
        let gettingStarted = try XCTUnwrap(book.chapter("1.1"))
        XCTAssertEqual(gettingStarted.title, "Getting Started with VoiceOver on iPhone")
        XCTAssertTrue(gettingStarted.sourceBody.contains("VoiceOver is a gesture-based screen reader built into iPhone."))
        XCTAssertEqual(book.chapter("1.8")?.title, "The Rotor")
        XCTAssertEqual(book.chapter("7.3")?.partID, "apps")
    }

    func testEveryChapterHasTheBookSections() {
        for chapter in book.chapters {
            let kinds = chapter.sections.map(\.kind)
            XCTAssertEqual(kinds.first, .overview, chapter.id)
            XCTAssertEqual(kinds.last, .sources, chapter.id)
            for required in [SectionKind.overview, .learn, .practice, .quickReference, .sources] {
                XCTAssertTrue(kinds.contains(required), "\(chapter.id) missing \(required)")
            }
            XCTAssertEqual(chapter.sections.first { $0.kind == .learn }?.heading, "What you'll learn")
            XCTAssertEqual(chapter.sections.first { $0.kind == .quickReference }?.heading, "Quick reference summary")
            XCTAssertFalse(chapter.sourceBody.isEmpty)
        }
    }

    func testSectionTextIsExactChapterText() {
        for chapter in book.chapters {
            var rebuilt: [String] = []
            for section in chapter.sections {
                XCTAssertFalse(section.text.isEmpty, "\(chapter.id) \(section.id)")
                XCTAssertTrue(chapter.sourceBody.contains(section.text), "\(chapter.id) \(section.sourceHeading)")
                if !section.sourceHeading.isEmpty {
                    XCTAssertTrue(chapter.sourceBody.contains(section.sourceHeading))
                    rebuilt.append(contentsOf: words(section.sourceHeading))
                }
                rebuilt.append(contentsOf: words(section.text))
                let lines = section.text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init).filter { !$0.isEmpty }
                let parsed = SectionBlocks.parse(section.text).flatMap { $0.text.split(separator: "\n").map(String.init) }
                XCTAssertEqual(parsed, lines, "\(chapter.id) \(section.id)")
            }
            XCTAssertEqual(rebuilt, words(chapter.sourceBody), chapter.id)
        }
    }

    func testReadmeTextIsUnchanged() {
        var rebuilt: [String] = []
        for section in book.readme.sections {
            XCTAssertTrue(book.readme.sourceBody.contains(section.text))
            if !section.sourceHeading.isEmpty {
                rebuilt.append(contentsOf: words(section.sourceHeading))
            }
            rebuilt.append(contentsOf: words(section.text))
        }
        XCTAssertEqual(rebuilt, words(book.readme.sourceBody))
        XCTAssertEqual(book.readme.sections.first?.heading, "Read me")
    }

    func testQuickReferenceIsOnlyQuickReferenceBullets() {
        let expected = ["about": 13, "iphone": 157, "ipad": 28, "mac": 50, "watch": 21, "tv": 15, "vision": 20, "apps": 14]
        for (partID, count) in expected {
            let items = book.quickReference(for: partID)
            XCTAssertEqual(items.count, count, partID)
            for item in items {
                XCTAssertEqual(item.text, "- \(item.line)")
                let chapter = book.chapter(item.chapterID)
                XCTAssertNotNil(chapter)
                let summary = chapter?.sections.first { $0.kind == .quickReference }
                XCTAssertTrue(summary?.text.contains(item.text) == true, item.text)
                XCTAssertEqual(item.partID, partID)
            }
        }
        XCTAssertFalse(book.quickReference(for: "iphone").contains { $0.line.localizedCaseInsensitiveContains("Reachability") })
        let core = book.chapter("1.3")?.sections.first { $0.kind == .quickReference }?.text ?? ""
        XCTAssertTrue(core.contains("- Swipe right for the next item. Swipe left for the previous item."))
        XCTAssertTrue(book.chapter("1.3")?.sections.contains { $0.sourceHeading == "REACHABILITY, IF YOUR IPHONE SUPPORTS IT" } == true)
    }

    func testIndexEntriesResolveToChapters() {
        for entry in book.index {
            XCTAssertFalse(entry.term.isEmpty)
            XCTAssertFalse(entry.chapters.isEmpty, entry.term)
            for id in entry.chapters {
                XCTAssertNotNil(book.chapter(id), "\(entry.term) -> \(id)")
            }
        }
        XCTAssertTrue(book.index.contains { $0.term == "Screen Curtain" && $0.chapters.contains("1.6") })
    }

    func testSearchRequiresEveryWordAndIgnoresCase() {
        let index = SearchIndex(book: book)
        XCTAssertTrue(index.search("").isEmpty)
        XCTAssertTrue(index.search("   ").isEmpty)
        XCTAssertTrue(index.search("zzzz-not-a-gesture qqqq").isEmpty)
        XCTAssertEqual(index.search("rotor").map(\.id), index.search("ROTOR").map(\.id))
        XCTAssertTrue(index.search("Screen Curtain").contains { $0.chapterID == "1.6" })
        XCTAssertTrue(index.search("braille screen").contains { $0.chapterID == "1.11" })
        let magic = index.search("magic tap")
        XCTAssertTrue(magic.contains { $0.chapterID == "1.4" })
        XCTAssertTrue(magic.allSatisfy { hit in
            let chapter = book.chapter(hit.chapterID)
            let hay = "\(chapter?.title ?? "") \(chapter?.sourceBody ?? "") \(hit.subtitle)".folded
            return hay.contains("magic") && hay.contains("tap")
        })
        let watch = index.search("VoiceOver", partID: "watch")
        XCTAssertFalse(watch.isEmpty)
        XCTAssertTrue(watch.allSatisfy { $0.partID == "watch" })
        let titleHit = index.search("Core Gestures").first { $0.chapterID == "1.3" && $0.subtitle == "Chapter title" }
        XCTAssertNotNil(titleHit)
        XCTAssertEqual(titleHit?.rank, 0)
    }

    func testOrientationAndPracticeDoNotInventGestures() {
        let orientation = OrientationCopy.plainText
        XCTAssertTrue(orientation.contains("not a chapter"))
        XCTAssertTrue(orientation.contains("does not add gestures or commands"))
        XCTAssertTrue(orientation.contains("triple-click the side button"))
        XCTAssertTrue(orientation.contains("Accessibility Shortcut"))
        XCTAssertTrue(orientation.contains("Settings > Accessibility > VoiceOver"))
        XCTAssertTrue(orientation.contains("Screen Curtain"))
        XCTAssertTrue(orientation.contains("Gestures change while VoiceOver is on"))
        XCTAssertFalse(orientation.localizedCaseInsensitiveContains("five-finger"))

        let practice = PracticeCopy.plainText
        XCTAssertTrue(practice.contains("does not add VoiceOver gestures"))
        XCTAssertTrue(practice.contains("Chapter 1.3"))
        XCTAssertTrue(practice.contains("Chapter 1.8"))
        XCTAssertTrue(practice.contains("Practice rotor"))
        XCTAssertFalse(practice.localizedCaseInsensitiveContains("five-finger"))
    }

    func testPrivacyPolicyCollectsNothing() {
        let text = PrivacyPolicy.sections.map { $0.heading + " " + $0.body }.joined(separator: " ")
        XCTAssertTrue(text.contains("does not collect"))
        XCTAssertTrue(text.contains("No accounts, ads, or tracking"))
        XCTAssertFalse(text.contains("["))
        XCTAssertFalse(text.contains("http"))
        XCTAssertEqual(TextSizeOption.allCases.count, 13)
        XCTAssertNil(TextSizeOption.system.dynamicTypeSize)
        XCTAssertEqual(TextSizeOption.accessibility5.dynamicTypeSize, .accessibility5)
    }
}
