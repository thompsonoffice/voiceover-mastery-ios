import Foundation
import Combine

enum BookError: LocalizedError {
    case missingResource
    case decode(Error)

    var errorDescription: String? {
        switch self {
        case .missingResource:
            return "The guide file is missing from the app."
        case .decode(let error):
            return error.localizedDescription
        }
    }
}

enum BookLoader {
    static func load(from data: Data) throws -> Book {
        do {
            return try JSONDecoder().decode(Book.self, from: data)
        } catch {
            throw BookError.decode(error)
        }
    }

    static func loadBundled(bundle: Bundle = .main) throws -> Book {
        guard let url = bundle.url(forResource: "book", withExtension: "json") else {
            throw BookError.missingResource
        }
        return try load(from: Data(contentsOf: url))
    }
}

/// The guide never changes after launch. EnvironmentObject keeps one copy for every screen.
final class Library: ObservableObject {
    let book: Book
    let searchIndex: SearchIndex

    init(book: Book) {
        self.book = book
        self.searchIndex = SearchIndex(book: book)
    }

    func search(_ query: String, partID: String? = nil) -> [SearchHit] {
        searchIndex.search(query, partID: partID)
    }
}
