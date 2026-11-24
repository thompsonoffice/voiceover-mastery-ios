import SwiftUI

@main
struct VoiceOverMasteryApp: App {
    @StateObject private var progress: ProgressStore
    @StateObject private var navigation: AppNavigation
    private let defaults: UserDefaults
    private let loaded: Result<Library, Error>

    init() {
        let defaults = VoiceOverMasteryApp.makeDefaults()
        self.defaults = defaults
        let store = ProgressStore(defaults: defaults)
        if let scene = ScreenshotLaunch.scene {
            store.applyScreenshotLaunch(scene)
        }
        _progress = StateObject(wrappedValue: store)
        let initialTab = ScreenshotLaunch.scene.map(AppTab.fromScreenshot) ?? .browse
        _navigation = StateObject(wrappedValue: AppNavigation(tab: initialTab))
        loaded = Result { try Library(book: BookLoader.loadBundled()) }
    }

    /// UI tests launch with -VoiceOverMasteryUITesting so they start from a clean store.
    private static func makeDefaults() -> UserDefaults {
        guard ProcessInfo.processInfo.arguments.contains("-VoiceOverMasteryUITesting")
                || ScreenshotLaunch.scene != nil,
              let suiteName = ProcessInfo.processInfo.arguments.contains("-VoiceOverMasteryUITesting")
                ? "VoiceOverMasteryUITesting"
                : "VoiceOverMasteryScreenshot",
              let suite = UserDefaults(suiteName: suiteName) else {
            return .standard
        }
        suite.removePersistentDomain(forName: suiteName)
        return suite
    }

    var body: some Scene {
        WindowGroup {
            switch loaded {
            case .success(let library):
                RootView()
                    .environmentObject(library)
                    .environmentObject(progress)
                    .environmentObject(navigation)
                    .defaultAppStorage(defaults)
                    #if os(macOS)
                    .onAppear { MacScreenshot.captureIfRequested() }
                    #endif
            case .failure(let error):
                Text("Access Mastery could not load its guide. \(error.localizedDescription)")
                    .font(.body)
                    .padding()
            }
        }
        #if os(macOS)
        .defaultSize(width: 1100, height: 740)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Go") {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button(tab.title) { navigation.tab = tab }
                        .keyboardShortcut(tab.shortcut, modifiers: .command)
                }
            }
            CommandGroup(after: .textEditing) {
                Button("Search") { navigation.tab = .search }
                    .keyboardShortcut("f", modifiers: .command)
            }
        }
        #endif
    }
}

struct RootView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @AppStorage(StrongContrast.storageKey) private var strongContrast = false

    var body: some View {
        GateView()
            .tint(Color.primary)
            .listRowSeparatorTint(Color.primary)
            .modifier(SolidScrollEdges())
            .environment(\.strongContrast, strongContrast)
            .modifier(ApplyTextSize(option: textSize))
    }
}

/// iOS 26 fades content at the scroll edge. That fade fails the contrast audit
/// on the last visible row. A hard edge keeps the text on a solid background.
struct SolidScrollEdges: ViewModifier {
    func body(content: Content) -> some View {
        #if os(iOS)
        let lifted = content.contentMargins(.bottom, 80, for: .scrollContent)
        if #available(iOS 26.0, *) {
            lifted.scrollEdgeEffectStyle(.hard, for: .all)
        } else {
            lifted
        }
        #else
        content
        #endif
    }
}

struct ApplyTextSize: ViewModifier {
    var option: TextSizeOption

    func body(content: Content) -> some View {
        if let size = option.dynamicTypeSize {
            content.dynamicTypeSize(size)
        } else {
            content
        }
    }
}

struct GateView: View {
    @EnvironmentObject private var progress: ProgressStore
    @EnvironmentObject private var library: Library

    var body: some View {
        if let scene = ScreenshotLaunch.scene, scene == "chapter",
           let chapter = library.book.chapter("3.1") {
            NavigationStack {
                ChapterReaderView(chapter: chapter)
            }
        } else if progress.audience == nil {
            AudienceView()
        } else if progress.audience == .sighted && !progress.orientationComplete {
            OrientationView(isGate: true)
        } else {
            ContentView()
        }
    }
}
