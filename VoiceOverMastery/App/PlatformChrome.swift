import SwiftUI

extension View {
    /// iOS-only compact navigation bar. On Mac the title already sits in the window toolbar.
    @ViewBuilder
    func inlineNavigationBar() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

/// Launch arguments used only by the screenshot helper on the Mac build runner.
enum ScreenshotLaunch {
    static var scene: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-VoiceOverMasteryScreenshot") else { return nil }
        if args.indices.contains(index + 1), !args[index + 1].hasPrefix("-") {
            return args[index + 1]
        }
        return "browse"
    }

    static var outputPath: String? {
        let args = ProcessInfo.processInfo.arguments
        guard let index = args.firstIndex(of: "-VoiceOverMasteryScreenshotPath"),
              args.indices.contains(index + 1) else { return nil }
        return args[index + 1]
    }
}

enum AppTab: String, Hashable, CaseIterable {
    case browse
    case search
    case reference
    case practice
    case more

    var title: String {
        switch self {
        case .browse: return "Browse"
        case .search: return "Search"
        case .reference: return "Reference"
        case .practice: return "Practice"
        case .more: return "More"
        }
    }

    var systemImage: String {
        switch self {
        case .browse: return "books.vertical"
        case .search: return "magnifyingglass"
        case .reference: return "list.bullet"
        case .practice: return "hand.tap"
        case .more: return "ellipsis.circle"
        }
    }

    var shortcut: KeyEquivalent {
        switch self {
        case .browse: return "1"
        case .search: return "2"
        case .reference: return "3"
        case .practice: return "4"
        case .more: return "5"
        }
    }

    static func fromScreenshot(_ scene: String) -> AppTab {
        switch scene {
        case "search": return .search
        case "reference": return .reference
        case "practice": return .practice
        case "more": return .more
        default: return .browse
        }
    }
}

final class AppNavigation: ObservableObject {
    @Published var tab: AppTab

    init(tab: AppTab = .browse) {
        self.tab = tab
    }
}
