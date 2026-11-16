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
                .tabItem { Label("Browse", systemImage: "books.vertical") }
                .tag(AppTab.browse)
            SearchView()
                .tabItem { Label("Search", systemImage: "magnifyingglass") }
                .tag(AppTab.search)
            QuickReferenceView()
                .tabItem { Label("Reference", systemImage: "list.bullet") }
                .tag(AppTab.reference)
            PracticeView()
                .tabItem { Label("Practice", systemImage: "hand.tap") }
                .tag(AppTab.practice)
            MoreView()
                .tabItem { Label("More", systemImage: "ellipsis.circle") }
                .tag(AppTab.more)
        }
    }
}
