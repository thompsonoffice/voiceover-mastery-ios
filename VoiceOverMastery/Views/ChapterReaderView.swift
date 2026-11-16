import SwiftUI

struct ChapterReaderView: View {
    let chapter: Chapter
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        let platform = library.book.part(chapter.partID)?.platform ?? ""
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(chapter.id). \(chapter.title)")
                            .font(.largeTitle.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h1)
                            .accessibilityIdentifier("chapterTitle")
                        Text(platform)
                            .font(.title3)
                            .supportingStyle()
                    }
                    ChapterActions(chapter: chapter, identifies: true)
                    inThisChapter(proxy: proxy)
                    ForEach(chapter.sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(section.heading)
                                .font(.title2.weight(.bold))
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityHeading(.h2)
                                .accessibilityIdentifier("heading-\(section.id)")
                            SectionBody(text: section.text, kind: section.kind)
                        }
                        .id(section.id)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End of chapter \(chapter.id)")
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                        ChapterActions(chapter: chapter)
                    }
                }
                .readableWidth()
                .padding()
            }
            .onAppear {
                let sectionToRestore = progress.lastChapterID == chapter.id ? progress.lastSectionID : nil
                progress.noteOpened(chapter.id)
                if let sectionToRestore {
                    DispatchQueue.main.async {
                        proxy.scrollTo(sectionToRestore, anchor: .top)
                    }
                }
            }
        }
        .navigationTitle(chapter.id)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func inThisChapter(proxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("In this chapter")
                .font(.title3.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
            ForEach(chapter.sections) { section in
                Button {
                    progress.noteSection(chapter.id, section.id)
                    proxy.scrollTo(section.id, anchor: .top)
                } label: {
                    Text(section.heading)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                }
                .buttonStyle(.bordered)
                .accessibilityHint("Moves to this section.")
                .accessibilityIdentifier("jump-\(section.id)")
            }
        }
    }
}
