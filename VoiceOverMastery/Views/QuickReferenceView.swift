import SwiftUI

struct QuickReferenceView: View {
    @EnvironmentObject private var library: Library
    @Environment(\.colorScheme) private var scheme

    private var ink: Color { scheme == .dark ? .white : .black }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
            Text("Each line is copied from a chapter's quick reference summary. The app does not add gestures.")
                .font(.body)
                .foregroundStyle(ink)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            List {
                Section {
                    SectionHeader("Devices")
                    ForEach(library.book.devices) { part in
                        NavigationLink(value: part.id) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(part.platform)
                                    .font(.body)
                                    .foregroundStyle(ink)
                                Text("\(library.book.quickReference(for: part.id).count) lines from quick reference summaries")
                                    .font(.body)
                                    .foregroundStyle(ink)
                            }
                            .padding(.vertical, 2)
                            .accessibilityElement(children: .combine)
                            .accessibilityIdentifier("quick-\(part.id)")
                            .accessibilityLabel("\(part.platform), quick reference")
                        }
                    }
                }
                Section {
                    SectionHeader("Also in this guide")
                    ForEach(library.book.parts.filter { !$0.isDevice }) { part in
                        NavigationLink(value: part.id) {
                            Text(part.platform)
                                .font(.body)
                        }
                        .accessibilityIdentifier("quick-\(part.id)")
                    }
                }
            }
            .navigationTitle("Reference")
            .navigationDestination(for: String.self) { partID in
                if let part = library.book.part(partID) {
                    QuickReferenceDetail(part: part)
                } else {
                    MissingView()
                }
            }
            }
        }
    }
}

struct QuickReferenceDetail: View {
    let part: Part
    @EnvironmentObject private var library: Library

    var body: some View {
        let items = library.book.quickReference(for: part.id)
        List {
            Section {
                Text("\(items.count) lines, copied from the quick reference summary in each \(part.platform) chapter.")
                    .font(.body)
            }
            ForEach(grouped(items), id: \.chapterID) { group in
                Section {
                    SectionHeader("\(group.chapterID). \(group.title)")
                    ForEach(group.items) { item in
                        NavigationLink(value: Route.chapter(item.chapterID)) {
                            Text(item.line)
                                .font(.body)
                        }
                        .accessibilityLabel(item.line)
                        .accessibilityHint("Quick reference from chapter \(item.chapterID), \(item.chapterTitle). Opens that chapter.")
                    }
                }
            }
        }
        .navigationTitle(part.platform)
        .navigationDestination(for: Route.self) { route in
            if case .chapter(let id) = route, let chapter = library.book.chapter(id) {
                ChapterReaderView(chapter: chapter)
            } else {
                MissingView()
            }
        }
    }

    private struct Group {
        var chapterID: String
        var title: String
        var items: [QuickReferenceItem]
    }

    private func grouped(_ items: [QuickReferenceItem]) -> [Group] {
        var groups: [Group] = []
        for item in items {
            if let index = groups.lastIndex(where: { $0.chapterID == item.chapterID }) {
                groups[index].items.append(item)
            } else {
                groups.append(Group(chapterID: item.chapterID, title: item.chapterTitle, items: [item]))
            }
        }
        return groups
    }
}
