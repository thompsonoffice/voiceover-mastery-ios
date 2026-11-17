import Foundation

struct SearchHit: Identifiable, Equatable {
    var id: String
    var chapterID: String
    var partID: String
    var sectionID: String?
    var title: String
    var subtitle: String
    var rank: Int
    var order: Int
}

/// Full-text search over chapter titles, section headings, section text, and the book's index.
/// Every word in the query must appear. Case and accents are ignored. Title matches rank first.
struct SearchIndex {
    private struct Document {
        var hit: SearchHit
        var haystack: String
    }

    private let documents: [Document]

    init(book: Book) {
        var order: [String: Int] = [:]
        for (index, chapter) in book.chapters.enumerated() {
            order[chapter.id] = index
        }
        var documents: [Document] = []
        for chapter in book.chapters {
            let position = order[chapter.id] ?? 0
            let titleHay = "\(chapter.id) \(chapter.title)".folded
            documents.append(Document(
                hit: SearchHit(
                    id: "\(chapter.id)|title",
                    chapterID: chapter.id,
                    partID: chapter.partID,
                    sectionID: nil,
                    title: "\(chapter.id). \(chapter.title)",
                    subtitle: "Chapter title",
                    rank: 0,
                    order: position
                ),
                haystack: titleHay
            ))
            for section in chapter.sections {
                let hay = "\(section.heading) \(section.sourceHeading) \(section.text)".folded
                let headingHay = "\(section.heading) \(section.sourceHeading)".folded
                documents.append(Document(
                    hit: SearchHit(
                        id: "\(chapter.id)|\(section.id)",
                        chapterID: chapter.id,
                        partID: chapter.partID,
                        sectionID: section.id,
                        title: "\(chapter.id). \(chapter.title)",
                        subtitle: section.heading,
                        rank: 2,
                        order: position
                    ),
                    haystack: hay
                ))
                documents.append(Document(
                    hit: SearchHit(
                        id: "\(chapter.id)|\(section.id)|heading",
                        chapterID: chapter.id,
                        partID: chapter.partID,
                        sectionID: section.id,
                        title: "\(chapter.id). \(chapter.title)",
                        subtitle: section.heading,
                        rank: 1,
                        order: position
                    ),
                    haystack: headingHay
                ))
            }
        }
        for entry in book.index {
            let hay = entry.term.folded
            for chapterID in entry.chapters {
                guard let chapter = book.chapter(chapterID) else { continue }
                documents.append(Document(
                    hit: SearchHit(
                        id: "\(chapterID)|index|\(entry.term)",
                        chapterID: chapterID,
                        partID: chapter.partID,
                        sectionID: nil,
                        title: "\(chapter.id). \(chapter.title)",
                        subtitle: "Index: \(entry.term)",
                        rank: 0,
                        order: order[chapterID] ?? 0
                    ),
                    haystack: hay
                ))
            }
        }
        self.documents = documents
    }

    func search(_ query: String, partID: String? = nil) -> [SearchHit] {
        let words = query.folded.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }
        let matches = documents.compactMap { document -> SearchHit? in
            guard partID == nil || document.hit.partID == partID else { return nil }
            guard words.allSatisfy({ document.haystack.contains($0) }) else { return nil }
            return document.hit
        }
        // A heading match and a body match for the same section collapse to the better rank.
        var best: [String: SearchHit] = [:]
        for hit in matches {
            let key = "\(hit.chapterID)|\(hit.sectionID ?? "none")|\(hit.subtitle)"
            if let existing = best[key], existing.rank <= hit.rank { continue }
            best[key] = hit
        }
        return best.values.sorted { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            if lhs.order != rhs.order { return lhs.order < rhs.order }
            return lhs.subtitle < rhs.subtitle
        }
    }
}
