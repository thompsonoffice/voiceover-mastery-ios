import SwiftUI

struct ContentView: View {
    #if os(iOS)
    @SceneStorage("VoiceOverMastery.selectedTab") private var tab: AppTab = .browse
    #endif

    var body: some View {
        #if os(macOS)
        MacContentView()
        #else
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
        #endif
    }
}

#if os(macOS)
struct MacContentView: View {
    @EnvironmentObject private var navigation: AppNavigation

    var body: some View {
        if #available(macOS 15.0, *) {
            TabView(selection: $navigation.tab) {
                Tab("Browse", systemImage: "books.vertical", value: AppTab.browse) {
                    BrowseView()
                }
                Tab("Search", systemImage: "magnifyingglass", value: AppTab.search) {
                    SearchView()
                }
                Tab("Reference", systemImage: "list.bullet", value: AppTab.reference) {
                    QuickReferenceView()
                }
                Tab("Practice", systemImage: "hand.tap", value: AppTab.practice) {
                    PracticeView()
                }
                Tab("More", systemImage: "ellipsis.circle", value: AppTab.more) {
                    MoreView()
                }
            }
            .tabViewStyle(.sidebarAdaptable)
        } else {
            NavigationSplitView {
                List(selection: $navigation.tab) {
                    ForEach(AppTab.allCases, id: \.self) { tab in
                        Label(tab.title, systemImage: tab.systemImage)
                            .tag(tab)
                            .accessibilityIdentifier("mac-tab-\(tab.rawValue)")
                    }
                }
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 260)
                .navigationTitle("Access Mastery")
            } detail: {
                switch navigation.tab {
                case .browse: BrowseView()
                case .search: SearchView()
                case .reference: QuickReferenceView()
                case .practice: PracticeView()
                case .more: MoreView()
                }
            }
        }
    }
}
#endif

/// iOS 26 draws the tab bar over the list and fades the rows underneath it.
/// The contrast audit measures that faded text. A fixed strip under the tab
/// content shortens the list so the last visible row sits above the bar.
struct BottomBarClearance: ViewModifier {
    @Environment(\.horizontalSizeClass) private var sizeClass

    func body(content: Content) -> some View {
        #if os(iOS)
        if sizeClass == .compact {
            VStack(spacing: 0) {
                content
                Color(.systemBackground)
                    .frame(height: 96)
                    .accessibilityHidden(true)
            }
        } else {
            content
        }
        #else
        content
        #endif
    }
}
