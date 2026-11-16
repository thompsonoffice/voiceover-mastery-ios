import SwiftUI

enum MoreRoute: Hashable {
    case bookmarks
    case settings
    case textSize
    case about
    case privacy
    case orientation
    case index
    case readme
}

struct MoreView: View {
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: MoreRoute.bookmarks) {
                        Label("Bookmarks", systemImage: "bookmark")
                    }
                    .accessibilityIdentifier("moreBookmarks")
                    NavigationLink(value: MoreRoute.settings) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .accessibilityIdentifier("moreSettings")
                }
                Section {
                    SectionHeader("Guide")
                    NavigationLink(value: MoreRoute.readme) {
                        Label("Book read me", systemImage: "text.book.closed")
                    }
                    NavigationLink(value: MoreRoute.index) {
                        Label("Index", systemImage: "list.bullet.rectangle")
                    }
                    NavigationLink(value: MoreRoute.orientation) {
                        Label("Sighted orientation", systemImage: "eye")
                    }
                    .accessibilityIdentifier("moreOrientation")
                }
                Section {
                    NavigationLink(value: MoreRoute.about) {
                        Label("About VoiceOver Mastery", systemImage: "info.circle")
                    }
                    .accessibilityIdentifier("moreAbout")
                    NavigationLink(value: MoreRoute.privacy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    .accessibilityIdentifier("morePrivacy")
                }
                if progress.audience != nil {
                    Section {
                        Button {
                            progress.clearAudience()
                        } label: {
                            Text("Choose again on the welcome screen")
                                .font(.body)
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Returns to the choice between using VoiceOver and learning it.")
                    }
                }
            }
            .modifier(SolidScrollEdges())
            .navigationTitle("More")
            .navigationDestination(for: MoreRoute.self) { route in
                switch route {
                case .bookmarks: BookmarksView()
                case .settings: SettingsView()
                case .textSize: TextSizeView()
                case .about: AboutView()
                case .privacy: PrivacyPolicyView()
                case .orientation: OrientationView(isGate: false)
                case .index: IndexView()
                case .readme: ReadmeView()
                }
            }
        }
    }
}

struct BookmarksView: View {
    @EnvironmentObject private var library: Library
    @EnvironmentObject private var progress: ProgressStore

    var body: some View {
        List {
            if progress.bookmarkIDs.isEmpty {
                Text("No bookmarks yet. Open a chapter and choose Bookmark. Bookmarks stay on this device.")
                    .font(.body)
                    .supportingStyle()
            } else {
                Section {
                    SectionHeader("\(progress.bookmarkIDs.count) saved on this device.")
                    ForEach(progress.bookmarkIDs, id: \.self) { id in
                        if let chapter = library.book.chapter(id) {
                            NavigationLink(value: Route.chapter(id)) {
                                ChapterLabel(chapter: chapter, platform: library.book.part(chapter.partID)?.platform ?? "")
                            }
                            .swipeActions {
                                Button("Remove bookmark", role: .destructive) {
                                    progress.removeBookmark(id)
                                }
                            }
                            .accessibilityAction(named: Text("Remove bookmark")) {
                                progress.removeBookmark(id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Bookmarks")
        .navigationDestination(for: Route.self) { route in
            if case .chapter(let id) = route, let chapter = library.book.chapter(id) {
                ChapterReaderView(chapter: chapter)
            } else {
                MissingView()
            }
        }
    }
}

struct TextSizeView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system

    var body: some View {
        List {
            ForEach(TextSizeOption.allCases) { option in
                Button {
                    textSize = option
                } label: {
                    HStack {
                        Text(option.title)
                            .font(.body)
                            .foregroundStyle(Color.primary)
                        Spacer()
                        if textSize == option {
                            Image(systemName: "checkmark")
                                .accessibilityHidden(true)
                        }
                    }
                    .frame(minHeight: 44)
                }
                .accessibilityLabel(option.title)
                .accessibilityAddTraits(textSize == option ? .isSelected : [])
            }
        }
        .navigationTitle("Text size")
    }
}

struct SettingsView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @AppStorage(StrongContrast.storageKey) private var strongContrast = false
    @EnvironmentObject private var progress: ProgressStore
    @State private var confirmCompleted = false
    @State private var confirmBookmarks = false

    var body: some View {
        Form {
            Section {
                SectionHeader("Reading")
                Text("Text size")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.primary)
                    .accessibilityAddTraits(.isHeader)
                ForEach(TextSizeOption.allCases) { option in
                    Button {
                        textSize = option
                    } label: {
                        HStack {
                            Text(option.title)
                                .font(.body)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if textSize == option {
                                Image(systemName: "checkmark")
                                    .accessibilityHidden(true)
                            }
                        }
                        .frame(minHeight: 44)
                    }
                    .accessibilityLabel(option.title)
                    .accessibilityAddTraits(textSize == option ? .isSelected : [])
                }
                Text("Sample. VoiceOver Mastery keeps chapter text at this size.")
                    .font(.body)
                    .accessibilityLabel("Text size sample. VoiceOver Mastery keeps chapter text at this size.")
                Toggle("Stronger contrast", isOn: $strongContrast)
                    .accessibilityHint("Uses primary text color and stronger borders, including when Increase Contrast is on.")
                Text("Every screen uses Dynamic Type. Use device setting follows Settings, Accessibility, Display and Text Size. Reduce Motion is followed by leaving extra animation off.")
                    .font(.body)
                    .foregroundStyle(Color.primary)
            }

            Section {
                SectionHeader("Saved on this device")
                if progress.completedIDs.isEmpty {
                    Text("No chapters are marked complete.")
                        .supportingStyle()
                } else {
                    Button("Clear completed chapters (\(progress.completedIDs.count))", role: .destructive) {
                        confirmCompleted = true
                    }
                }
                if progress.bookmarkIDs.isEmpty {
                    Text("No bookmarks to remove.")
                        .supportingStyle()
                } else {
                    Button("Remove all bookmarks (\(progress.bookmarkIDs.count))", role: .destructive) {
                        confirmBookmarks = true
                    }
                }
                if progress.lastChapterID == nil {
                    Text("No chapter to resume.")
                        .supportingStyle()
                } else {
                    Button("Clear resume position", role: .destructive) {
                        progress.clearResume()
                    }
                }
                Text("Progress and bookmarks are stored only on this device. Nothing is sent anywhere.")
                    .font(.body)
                    .foregroundStyle(Color.primary)
            }
        }
        .navigationTitle("Settings")
        .confirmationDialog("Clear completed chapters?", isPresented: $confirmCompleted, titleVisibility: .visible) {
            Button("Clear completed chapters", role: .destructive) { progress.clearCompleted() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Remove all bookmarks?", isPresented: $confirmBookmarks, titleVisibility: .visible) {
            Button("Remove all bookmarks", role: .destructive) { progress.clearBookmarks() }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct AboutView: View {
    @EnvironmentObject private var library: Library

    private var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About VoiceOver Mastery")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)
                section("What this is") {
                    Text("VoiceOver Mastery is an offline reader for the book VoiceOver Mastery: The Complete Apple Guide, a title in SRTS: Screen Reader Training Suite. The chapters are the book's text. The app adds browsing by device, search, bookmarks, progress, a quick reference built only from each chapter's quick reference summary, and a practice screen of real controls.")
                    Text("This app is not an Apple manual, and it is not affiliated with, endorsed by, or published by Apple. Apple's user guides remain the authority when a setting or gesture changes.")
                    Text("Planned App Store price: $3.99. This app does not include a purchase link.")
                }
                section("What is included") {
                    labeled("Edition", library.book.edition)
                    labeled("Chapters", String(library.book.chapters.count))
                    labeled("Devices", library.book.devices.map(\.platform).joined(separator: ", "))
                    labeled("Chapter words", String(library.book.wordCount))
                    labeled("Index entries", String(library.book.index.count))
                }
                section("Privacy") {
                    Text("VoiceOver Mastery works offline and collects no data. Progress and bookmarks stay on this device.")
                    NavigationLink("Read the privacy policy", value: MoreRoute.privacy)
                }
                labeled("Developer", library.book.author)
                labeled("Version", version)
            }
            .readableWidth()
            .padding()
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title2.weight(.bold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityHeading(.h2)
            content()
                .font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.subheadline.weight(.semibold))
            Text(value).font(.body)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("VoiceOver Mastery Privacy Policy")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)
                Text("Effective \(PrivacyPolicy.effectiveDate)")
                    .font(.body)
                ForEach(PrivacyPolicy.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.heading)
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                        Text(section.body)
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .readableWidth()
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct IndexView: View {
    @EnvironmentObject private var library: Library

    var body: some View {
        List {
            Section {
                Text("Topics from the book's index. Choosing a chapter opens it. The index does not add entries.")
                    .font(.body)
                    .supportingStyle()
            }
            ForEach(library.book.index) { entry in
                Section {
                    SectionHeader(entry.term)
                    ForEach(entry.chapters, id: \.self) { id in
                        if let chapter = library.book.chapter(id) {
                            NavigationLink(value: Route.chapter(id)) {
                                Text("\(chapter.id). \(chapter.title)")
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Index")
        .navigationDestination(for: Route.self) { route in
            if case .chapter(let id) = route, let chapter = library.book.chapter(id) {
                ChapterReaderView(chapter: chapter)
            } else {
                MissingView()
            }
        }
    }
}

struct ReadmeView: View {
    @EnvironmentObject private var library: Library

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text("Book read me")
                    .font(.largeTitle.weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityHeading(.h1)
                Text("The book's own read-me text, unchanged.")
                    .font(.body)
                    .supportingStyle()
                ForEach(library.book.readme.sections) { section in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.heading)
                            .font(.title2.weight(.bold))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityHeading(.h2)
                        SectionBody(text: section.text, kind: section.kind)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .readableWidth()
            .padding()
        }
        .navigationTitle("Read me")
        .navigationBarTitleDisplayMode(.inline)
    }
}
