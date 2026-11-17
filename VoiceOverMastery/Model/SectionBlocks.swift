import Foundation

struct ContentBlock: Equatable {
    enum Kind: Equatable {
        case paragraph
        case bullet
        case step
        case source
    }

    var kind: Kind
    var text: String

    var sourceLines: [String] {
        text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
    }
}

/// Splits a section body into paragraphs, bullets, numbered steps, and source links.
/// The block text is the original lines. Words are not rewritten.
enum SectionBlocks {
    static func parse(_ text: String) -> [ContentBlock] {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var blocks: [ContentBlock] = []
        var paragraph: [String] = []

        func flushParagraph() {
            let content = paragraph.filter { !$0.isEmpty }
            paragraph = []
            guard !content.isEmpty else { return }
            if content.count == 2, content[1].hasPrefix("http://") || content[1].hasPrefix("https://") {
                blocks.append(ContentBlock(kind: .source, text: content.joined(separator: "\n")))
            } else {
                blocks.append(ContentBlock(kind: .paragraph, text: content.joined(separator: "\n")))
            }
        }

        var index = 0
        while index < lines.count {
            let line = lines[index]
            if line.trimmingCharacters(in: .whitespaces).isEmpty {
                flushParagraph()
                index += 1
                continue
            }
            if isStep(line) {
                flushParagraph()
                var chunk = [line]
                index += 1
                while index < lines.count, isIndentedBullet(lines[index]) {
                    chunk.append(lines[index])
                    index += 1
                }
                blocks.append(ContentBlock(kind: .step, text: chunk.joined(separator: "\n")))
                continue
            }
            if isBullet(line) {
                flushParagraph()
                blocks.append(ContentBlock(kind: .bullet, text: line))
                index += 1
                continue
            }
            paragraph.append(line)
            index += 1
        }
        flushParagraph()
        return blocks
    }

    private static func isStep(_ line: String) -> Bool {
        line.range(of: #"^\d+\. "#, options: .regularExpression) != nil
    }

    private static func isIndentedBullet(_ line: String) -> Bool {
        line.hasPrefix(" ") && line.trimmingCharacters(in: .whitespaces).hasPrefix("- ")
    }

    private static func isBullet(_ line: String) -> Bool {
        isIndentedBullet(line) || line.hasPrefix("- ")
    }
}
