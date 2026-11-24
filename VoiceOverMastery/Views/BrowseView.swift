import SwiftUI

enum Route: Hashable {
    case part(String)
    case chapter(String)
}

struct BrowseView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        if sizeClass == .regular {
            RegularBrowseView()
        } else {
            CompactBrowseView()
        }
    }
}

struct CompactBrowseView: View {
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        NavigationStack {
            List {
                progressSection
                partSection(title: "Devices", parts: library.book.devices)
                partSection(title: "Also in this guide", parts: library.book.parts.filter { !$0.isDevice })
            }
            .modifier(SolidScrollEdges())
            .navigationTitle("Screen Reader Mastery")
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .part(let id):
                    if let part = library.book.part(id) {
                        ChapterListView(part: part)
                    } else {
                        MissingView()
                    }
                case .chapter(let id):
                    if let chapter = library.book.chapter(id) {
                        ChapterReaderView(chapter: chapter)
                    } else {
                        MissingView()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        Section {
            SectionHeader("Continue")
            Text(summary)
                .font(.body)
                .accessibilityIdentifier("progressSummary")
            if let chapter = progress.resumeChapter(in: library.book) {
                NavigationLink(value: Route.chapter(chapter.id)) {
                    ResumeLabel(chapter: chapter, sectionTitle: progress.resumeSectionTitle(in: library.book))
                }
                .accessibilityIdentifier("resume")
            }
        }
    }

    private var summary: String {
        let done = progress.completedIDs.count
        let total = library.book.chapters.count
        return "\(done) of \(total) chapters complete."
    }

    private func partSection(title: String, parts: [Part]) -> some View {
        Section {
            SectionHeader(title)
            ForEach(parts) { part in
                NavigationLink(value: Route.part(part.id)) {
                    PartLabel(part: part)
                }
                .accessibilityIdentifier("part-\(part.id)")
            }
        }
    }
}

struct RegularBrowseView: View {
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var progress: ProgressStore
    @State private var partID: String? = "iphone"
    @State private var chapterID: String?

    var body: some View {
        NavigationSplitView {
            List(selection: $partID) {
                Section {
                    SectionHeader("Continue")
                    Text(summary)
                        .font(.body)
                        .accessibilityIdentifier("progressSummary")
                    if let chapter = progress.resumeChapter(in: library.book) {
                        Button {
                            partID = chapter.partID
                            chapterID = chapter.id
                        } label: {
                            ResumeLabel(chapter: chapter, sectionTitle: progress.resumeSectionTitle(in: library.book))
                        }
                        .accessibilityIdentifier("resume")
                    }
                }
                Section {
                    SectionHeader("Devices")
                    ForEach(library.book.devices) { part in
                        PartLabel(part: part)
                            .tag(part.id as String?)
                            .accessibilityIdentifier("part-\(part.id)")
                    }
                }
                Section {
                    SectionHeader("Also in this guide")
                    ForEach(library.book.parts.filter { !$0.isDevice }) { part in
                        PartLabel(part: part)
                            .tag(part.id as String?)
                            .accessibilityIdentifier("part-\(part.id)")
                    }
                }
            }
            .modifier(SolidScrollEdges())
            .navigationTitle("Screen Reader Mastery")
        } content: {
            if let partID, let part = library.book.part(partID) {
                ChapterSelectableList(part: part, selection: $chapterID)
            } else {
                Text("Choose a device or a part of the guide.")
                    .font(.body)
                    .padding()
            }
        } detail: {
            if let chapterID, let chapter = library.book.chapter(chapterID) {
                ChapterReaderView(chapter: chapter)
            } else {
                Text("Choose a chapter to read it.")
                    .font(.body)
                    .padding()
            }
        }
    }

    private var summary: String {
        "\(progress.completedIDs.count) of \(library.book.chapters.count) chapters complete."
    }
}

struct ResumeLabel: View {
    let chapter: Chapter
    let sectionTitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Resume \(chapter.id). \(chapter.title)")
                .font(.body.weight(.semibold))
            if let sectionTitle {
                Text(sectionTitle)
                    .font(.subheadline)
                    .supportingStyle()
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityHint("Opens the chapter you were reading.")
    }

    private var label: String {
        if let sectionTitle {
            return "Resume \(chapter.id). \(chapter.title), \(sectionTitle)"
        }
        return "Resume \(chapter.id). \(chapter.title)"
    }
}

struct ChapterListView: View {
    let part: Part

    var body: some View {
        List {
            Section {
                SectionHeader("\(part.chapters.count) chapters. \(part.title).")
                ForEach(part.chapters) { chapter in
                    NavigationLink(value: Route.chapter(chapter.id)) {
                        ChapterLabel(chapter: chapter, platform: part.platform)
                    }
                    .accessibilityIdentifier("chapter-\(chapter.id)")
                }
            }
        }
        .navigationTitle(part.platform)
    }
}

struct ChapterSelectableList: View {
    let part: Part
    @Binding var selection: String?

    var body: some View {
        List(selection: $selection) {
            ForEach(part.chapters) { chapter in
                ChapterLabel(chapter: chapter, platform: part.platform)
                    .tag(chapter.id as String?)
                    .accessibilityIdentifier("chapter-\(chapter.id)")
            }
        }
        .navigationTitle(part.platform)
    }
}
