import Foundation
import Combine

/// Reading progress, bookmarks, and the first-launch audience choice.
/// Stored only in UserDefaults on this device.
final class ProgressStore: ObservableObject {
    static let completedKey = "voiceovermastery.completed"
    static let bookmarksKey = "voiceovermastery.bookmarks"
    static let lastChapterKey = "voiceovermastery.lastChapter"
    static let lastSectionKey = "voiceovermastery.lastSection"
    static let audienceKey = "voiceovermastery.audience"
    static let orientationKey = "voiceovermastery.orientationComplete"

    enum Audience: String {
        case voiceOver
        case sighted
    }

    @Published private(set) var completedIDs: [String]
    @Published private(set) var bookmarkIDs: [String]
    @Published private(set) var lastChapterID: String?
    @Published private(set) var lastSectionID: String?
    @Published private(set) var audience: Audience?
    @Published private(set) var orientationComplete: Bool

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedIDs = defaults.stringArray(forKey: Self.completedKey) ?? []
        bookmarkIDs = defaults.stringArray(forKey: Self.bookmarksKey) ?? []
        lastChapterID = defaults.string(forKey: Self.lastChapterKey)
        lastSectionID = defaults.string(forKey: Self.lastSectionKey)
        if let raw = defaults.string(forKey: Self.audienceKey) {
            audience = Audience(rawValue: raw)
        } else {
            audience = nil
        }
        orientationComplete = defaults.bool(forKey: Self.orientationKey)
    }

    func isComplete(_ id: String) -> Bool { completedIDs.contains(id) }
    func isBookmarked(_ id: String) -> Bool { bookmarkIDs.contains(id) }

    func toggleComplete(_ id: String) {
        if let index = completedIDs.firstIndex(of: id) {
            completedIDs.remove(at: index)
        } else {
            completedIDs.append(id)
        }
        defaults.set(completedIDs, forKey: Self.completedKey)
    }

    func toggleBookmark(_ id: String) {
        if let index = bookmarkIDs.firstIndex(of: id) {
            bookmarkIDs.remove(at: index)
        } else {
            bookmarkIDs.insert(id, at: 0)
        }
        defaults.set(bookmarkIDs, forKey: Self.bookmarksKey)
    }

    func removeBookmark(_ id: String) {
        bookmarkIDs.removeAll { $0 == id }
        defaults.set(bookmarkIDs, forKey: Self.bookmarksKey)
    }

    /// Records the open chapter. A different chapter clears the saved section.
    func noteOpened(_ chapterID: String) {
        if lastChapterID != chapterID {
            lastChapterID = chapterID
            lastSectionID = nil
            defaults.set(chapterID, forKey: Self.lastChapterKey)
            defaults.removeObject(forKey: Self.lastSectionKey)
        } else {
            lastChapterID = chapterID
            defaults.set(chapterID, forKey: Self.lastChapterKey)
        }
    }

    func noteSection(_ chapterID: String, _ sectionID: String) {
        lastChapterID = chapterID
        lastSectionID = sectionID
        defaults.set(chapterID, forKey: Self.lastChapterKey)
        defaults.set(sectionID, forKey: Self.lastSectionKey)
    }

    func resumeChapter(in book: Book) -> Chapter? {
        guard let lastChapterID else { return nil }
        return book.chapter(lastChapterID)
    }

    func resumeSectionTitle(in book: Book) -> String? {
        guard let chapter = resumeChapter(in: book), let lastSectionID else { return nil }
        return chapter.sections.first { $0.id == lastSectionID }?.heading
    }

    func choose(_ audience: Audience) {
        self.audience = audience
        orientationComplete = audience == .voiceOver
        defaults.set(audience.rawValue, forKey: Self.audienceKey)
        defaults.set(orientationComplete, forKey: Self.orientationKey)
    }

    func completeOrientation() {
        orientationComplete = true
        defaults.set(true, forKey: Self.orientationKey)
    }

    func clearAudience() {
        audience = nil
        defaults.removeObject(forKey: Self.audienceKey)
    }

    func clearCompleted() {
        completedIDs = []
        defaults.set(completedIDs, forKey: Self.completedKey)
    }

    func clearBookmarks() {
        bookmarkIDs = []
        defaults.set(bookmarkIDs, forKey: Self.bookmarksKey)
    }

    func clearResume() {
        lastChapterID = nil
        lastSectionID = nil
        defaults.removeObject(forKey: Self.lastChapterKey)
        defaults.removeObject(forKey: Self.lastSectionKey)
    }
}
