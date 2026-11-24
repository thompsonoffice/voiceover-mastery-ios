import Foundation

/// A part of the guide. Device parts are iPhone, iPad, Mac, Apple Watch, Apple TV, and Apple Vision Pro.
struct Part: Codable, Identifiable {
    var id: String
    var number: Int
    var title: String
    var platform: String
    var isDevice: Bool
    var chapters: [Chapter]
}

struct Chapter: Codable, Identifiable {
    var id: String
    var title: String
    var partID: String
    var file: String
    /// Exact chapter text after the plain-text banner, copied from the source file.
    var sourceBody: String
    var sections: [ChapterSection]
}

enum SectionKind: String, Codable {
    case overview
    case learn
    case teaching
    case practice
    case quickReference
    case sources
}

struct ChapterSection: Codable, Identifiable {
    var id: String
    var kind: SectionKind
    /// Heading as printed in the chapter, for example "OVERVIEW". Empty for the read-me preamble.
    var sourceHeading: String
    /// Sentence-case heading spoken by VoiceOver. The section body is not rewritten.
    var heading: String
    /// Exact section body from the chapter.
    var text: String
}

struct IndexEntry: Codable, Identifiable {
    var term: String
    var chapters: [String]
    var id: String { term }
}

struct ReadmeDocument: Codable {
    var sections: [ChapterSection]
    var sourceBody: String
}

struct Book: Codable {
    var title: String
    var fullTitle: String
    var series: String
    var edition: String
    var author: String
    var chapterCount: Int
    var wordCount: Int
    var parts: [Part]
    var index: [IndexEntry]
    var readme: ReadmeDocument

    static let empty = Book(
        title: "Access Mastery",
        fullTitle: "Access Mastery",
        series: "",
        edition: "",
        author: "",
        chapterCount: 0,
        wordCount: 0,
        parts: [],
        index: [],
        readme: ReadmeDocument(sections: [], sourceBody: "")
    )

    var chapters: [Chapter] { parts.flatMap(\.chapters) }
    var devices: [Part] { parts.filter(\.isDevice) }

    func part(_ id: String) -> Part? { parts.first { $0.id == id } }
    func chapter(_ id: String) -> Chapter? { chapters.first { $0.id == id } }
}

/// One bullet copied from a chapter's Quick reference summary. Nothing is added.
struct QuickReferenceItem: Identifiable, Equatable {
    var partID: String
    var chapterID: String
    var chapterTitle: String
    var text: String
    var index: Int
    var id: String { "\(chapterID)#\(index)" }

    /// The bullet words, without the leading "- " marker.
    var line: String {
        text.hasPrefix("- ") ? String(text.dropFirst(2)) : text
    }
}

extension Book {
    func quickReference(for partID: String) -> [QuickReferenceItem] {
        guard let part = part(partID) else { return [] }
        var items: [QuickReferenceItem] = []
        for chapter in part.chapters {
            guard let section = chapter.sections.first(where: { $0.kind == .quickReference }) else { continue }
            let lines = section.text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
            var count = 0
            for line in lines where line.hasPrefix("- ") {
                items.append(QuickReferenceItem(
                    partID: partID,
                    chapterID: chapter.id,
                    chapterTitle: chapter.title,
                    text: line,
                    index: count
                ))
                count += 1
            }
        }
        return items
    }
}

extension String {
    /// Case- and accent-insensitive form used by search.
    var folded: String {
        folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX")).lowercased()
    }
}
