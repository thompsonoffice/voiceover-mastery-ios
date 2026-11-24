import SwiftUI

struct ReadableWidth: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: 800, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func readableWidth() -> some View { modifier(ReadableWidth()) }

    func supportingStyle() -> some View { modifier(SupportingStyle()) }
}

struct SupportingStyle: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.strongContrast) private var strong

    func body(content: Content) -> some View {
        content
            .foregroundStyle(.primary)
            .fontWeight(contrast == .increased || strong ? .semibold : .regular)
    }
}

struct SectionHeader: View {
    var title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        // A normal list row, not a system section header. System headers use a gray
        // that the accessibility audit rejects.
        Text(title)
            .font(.title3.weight(.bold))
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(title)
            .accessibilityAddTraits(.isHeader)
            .accessibilityHeading(.h2)
    }
}

struct MissingView: View {
    var body: some View {
        Text("This part of the guide is not available.")
            .font(.body)
            .padding()
    }
}

struct CopySections: View {
    var sections: [CopySection]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 8) {
                    Text(section.heading)
                        .font(.title2.weight(.bold))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityHeading(.h2)
                    ForEach(section.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                            .font(.body)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

/// Renders a chapter section without changing its words.
struct SectionBody: View {
    var text: String
    var kind: SectionKind
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.strongContrast) private var strong

    private var emphasize: Bool { strong || contrast == .increased }

    var body: some View {
        let blocks = SectionBlocks.parse(text)
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func blockView(_ block: ContentBlock) -> some View {
        switch block.kind {
        case .paragraph:
            Text(block.text)
                .font(.body)
        case .bullet:
            Text(bulletWords(block.text))
                .font(.body)
                .padding(.leading, 8)
                .accessibilityLabel(bulletWords(block.text))
        case .step:
            Text(block.text)
                .font(.body)
                .padding(emphasize ? 8 : 0)
                .overlay {
                    if emphasize {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary, lineWidth: 1)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                }
        case .source:
            sourceView(block)
        }
    }

    private func bulletWords(_ line: String) -> String {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("- ") { return String(trimmed.dropFirst(2)) }
        return trimmed
    }

    @ViewBuilder
    private func sourceView(_ block: ContentBlock) -> some View {
        let lines = block.sourceLines
        if lines.count == 2, let url = URL(string: lines[1]), url.scheme?.hasPrefix("http") == true {
            VStack(alignment: .leading, spacing: 4) {
                Text(lines[0])
                    .font(.body)
                Link(destination: url) {
                    Text(lines[1])
                        .font(.body)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .accessibilityHint("Opens this source in your browser.")
            }
        } else {
            Text(block.text)
                .font(.body)
        }
    }
}

struct ChapterActions: View {
    let chapter: Chapter
    var identifies = false
    @EnvironmentObject private var progress: ProgressStore
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.strongContrast) private var strong

    var body: some View {
        let bookmarked = progress.isBookmarked(chapter.id)
        let complete = progress.isComplete(chapter.id)
        VStack(alignment: .leading, spacing: 8) {
            Button {
                progress.toggleComplete(chapter.id)
            } label: {
                Text(complete ? "Completed" : "Mark chapter complete")
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .accessibilityLabel(complete ? "Completed" : "Mark chapter complete")
            .accessibilityAddTraits(complete ? .isSelected : [])
            .accessibilityHint(complete ? "Marks this chapter as not complete." : "Marks this chapter complete on this device.")
            .modifier(OptionalIdentifier(identifies ? "markComplete" : nil))

            Button {
                progress.toggleBookmark(chapter.id)
            } label: {
                Text(bookmarked ? "Bookmarked" : "Bookmark")
                    .font(.body)
                    .foregroundStyle(Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            }
            .accessibilityLabel(bookmarked ? "Bookmarked" : "Bookmark")
            .accessibilityAddTraits(bookmarked ? .isSelected : [])
            .accessibilityHint(bookmarked ? "Removes this chapter from Bookmarks." : "Saves this chapter in Bookmarks on this device.")
            .modifier(OptionalIdentifier(identifies ? "bookmarkChapter" : nil))
        }
        .buttonStyle(.bordered)
        .overlay {
            if strong || contrast == .increased {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary, lineWidth: 2)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

struct OptionalIdentifier: ViewModifier {
    var identifier: String?

    init(_ identifier: String?) {
        self.identifier = identifier
    }

    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityIdentifier(identifier)
        } else {
            content
        }
    }
}

struct PartLabel: View {
    let part: Part
    @Environment(\.colorScheme) private var scheme

    private var ink: Color { scheme == .dark ? .white : .black }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(part.platform)
                .font(.body)
                .foregroundStyle(ink)
            Text("\(part.chapters.count) \(part.chapters.count == 1 ? "chapter" : "chapters")")
                .font(.body)
                .foregroundStyle(ink)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(scheme == .dark ? Color.black : Color.white)
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(part.platform), \(part.chapters.count) \(part.chapters.count == 1 ? "chapter" : "chapters")")
    }
}

struct ChapterLabel: View {
    let chapter: Chapter
    let platform: String
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        let complete = progress.isComplete(chapter.id)
        let bookmarked = progress.isBookmarked(chapter.id)
        VStack(alignment: .leading, spacing: 2) {
            Text("\(chapter.id). \(chapter.title)")
                .font(.body.weight(.semibold))
            Text(status(complete: complete, bookmarked: bookmarked))
                .font(.subheadline)
                .supportingStyle()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chapter.id). \(chapter.title), \(platform), \(status(complete: complete, bookmarked: bookmarked))")
    }

    private func status(complete: Bool, bookmarked: Bool) -> String {
        var pieces = [complete ? "Complete" : "Not complete"]
        if bookmarked { pieces.append("Bookmarked") }
        return pieces.joined(separator: ", ")
    }
}
