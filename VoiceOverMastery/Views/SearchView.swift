import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var library: Library
    @State private var query = ""
    @State private var partFilter = "all"
    @State private var announceTask: Task<Void, Never>?

    private var hits: [SearchHit] {
        let part = partFilter == "all" ? nil : partFilter
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return library.search(trimmed, partID: part)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Part", selection: $partFilter) {
                        Text("All parts").tag("all")
                        ForEach(library.book.parts) { part in
                            Text(part.platform).tag(part.id)
                        }
                    }
                    .accessibilityHint("Limits results to one part of the guide.")
                }
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Search the chapters, including headings, steps, quick reference lines, and the index. Every word must match. For example: rotor, Screen Curtain, Magic Tap.")
                        .font(.body)
                        .supportingStyle()
                } else {
                    Section {
                        Text(hits.count == 1 ? "1 result" : "\(hits.count) results")
                            .font(.body)
                            .accessibilityIdentifier("resultCount")
                    }
                    if hits.isEmpty {
                        Text("No matches.")
                            .font(.body)
                            .supportingStyle()
                    } else {
                        Section {
                            ForEach(hits) { hit in
                                NavigationLink(value: Route.chapter(hit.chapterID)) {
                                    SearchHitLabel(hit: hit)
                                }
                            }
                        } header: {
                            SectionHeader("Results")
                        }
                    }
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Chapters, gestures, settings")
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .navigationTitle("Search")
            .navigationDestination(for: Route.self) { route in
                if case .chapter(let id) = route, let chapter = library.book.chapter(id) {
                    ChapterReaderView(chapter: chapter)
                } else {
                    MissingView()
                }
            }
            .onChange(of: query) { _, _ in announceCount() }
            .onChange(of: partFilter) { _, _ in announceCount() }
        }
    }

    private func announceCount() {
        announceTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let part = partFilter == "all" ? nil : partFilter
        announceTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            guard !Task.isCancelled else { return }
            let count = library.search(trimmed, partID: part).count
            AccessibilityNotification.Announcement(count == 1 ? "1 result" : "\(count) results").post()
        }
    }
}

struct SearchHitLabel: View {
    let hit: SearchHit
    @EnvironmentObject private var library: Library

    var body: some View {
        let platform = library.book.part(hit.partID)?.platform ?? ""
        VStack(alignment: .leading, spacing: 2) {
            Text(hit.title)
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text("\(platform). \(hit.subtitle)")
                .font(.subheadline)
                .supportingStyle()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(hit.title), \(platform), \(hit.subtitle)")
    }
}
