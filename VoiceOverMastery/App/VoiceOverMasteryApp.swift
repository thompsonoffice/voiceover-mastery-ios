import SwiftUI

@main
struct VoiceOverMasteryApp: App {
    @StateObject private var progress: ProgressStore
    private let defaults: UserDefaults
    private let loaded: Result<Library, Error>

    init() {
        let defaults = VoiceOverMasteryApp.makeDefaults()
        self.defaults = defaults
        _progress = StateObject(wrappedValue: ProgressStore(defaults: defaults))
        loaded = Result { try Library(book: BookLoader.loadBundled()) }
    }

    /// UI tests launch with -VoiceOverMasteryUITesting so they start from a clean store.
    private static func makeDefaults() -> UserDefaults {
        guard ProcessInfo.processInfo.arguments.contains("-VoiceOverMasteryUITesting"),
              let suite = UserDefaults(suiteName: "VoiceOverMasteryUITesting") else {
            return .standard
        }
        suite.removePersistentDomain(forName: "VoiceOverMasteryUITesting")
        return suite
    }

    var body: some Scene {
        WindowGroup {
            switch loaded {
            case .success(let library):
                RootView()
                    .environmentObject(library)
                    .environmentObject(progress)
                    .defaultAppStorage(defaults)
            case .failure(let error):
                Text("VoiceOver Mastery could not load its guide. \(error.localizedDescription)")
                    .font(.body)
                    .padding()
            }
        }
    }
}

struct RootView: View {
    @AppStorage(TextSizeOption.storageKey) private var textSize: TextSizeOption = .system
    @AppStorage(StrongContrast.storageKey) private var strongContrast = false

    var body: some View {
        GateView()
            .tint(Color.primary)
            .environment(\.strongContrast, strongContrast)
            .modifier(ApplyTextSize(option: textSize))
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

    var body: some View {
        if progress.audience == nil {
            AudienceView()
        } else if progress.audience == .sighted && !progress.orientationComplete {
            OrientationView(isGate: true)
        } else {
            ContentView()
        }
    }
}
