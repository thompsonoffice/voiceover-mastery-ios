import SwiftUI

enum AppTab: String {
    case browse
    case search
    case reference
    case practice
    case more
}

struct ContentView: View {
    @SceneStorage("VoiceOverMastery.selectedTab") private var tab: AppTab = .browse

    var body: some View {
        TabView(selection: $tab) {
            BrowseView()
                .modifier(BottomBarClearance())
                .tabItem { Label("Browse", systemImage: "books.vertical") }
                .tag(AppTab.browse)
            SearchView()
                .modifier(BottomBarClearance())
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)
            QuickReferenceView()
                .modifier(BottomBarClearance())
                .tabItem { Label("Reference", systemImage: "list.bullet") }
                .tag(AppTab.reference)
            PracticeView()
                .modifier(BottomBarClearance())
                .tabItem { Label("Practice", systemImage: "hand.tap") }
                .tag(AppTab.practice)
            MoreView()
                .modifier(BottomBarClearance())
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(AppTab.more)
        }
    }
}

/// iOS 26 draws the tab bar over the list and fades the rows underneath it.
/// The contrast audit measures that faded text. This inset ends the list above the bar.
struct BottomBarClearance: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        if sizeClass == .compact {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                Color(.systemBackground)
                    .frame(height: 160)
                    .accessibilityHidden(true)
            }
        } else {
            content
        }
    }
}
