import SwiftUI

struct TabBarView: View {
    
    static let kMiniPlayerOffet = -54.0
    static let kTabContentBottomOffset = 60.0
    
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(StateManager.self) private var stateManager
    
    @SceneStorage("selectedTab")
    private var selectedTab: AppTab = .news
    
    let animationID: Namespace.ID
    
    var body: some View {
        if #available(iOS 26, *) {
            iOS18TabBarView(Self.kTabContentBottomOffset)
                .overlay(alignment: .bottom) {
                    HStack {
                        MiniPlayerView()
                            .matchedTransitionSource(id: AnimationID.playerView.rawValue, in: animationID)
                            .glassEffect(.regular.interactive())
                            .onTapGesture {
                                stateManager.expandPlayer()
                            }
                        
                        ListeningControl()
                    }
                    .offset(y: Self.kMiniPlayerOffet)
                    .padding(.horizontal)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
        } else
        if #available(iOS 18.0, *) {
            iOS18TabBarView(Self.kTabContentBottomOffset)
                .overlay(alignment: .bottom) {
                    HStack {
                        MiniPlayerViewWithBackground()
                            .matchedTransitionSource(id: AnimationID.playerView.rawValue, in: animationID)
                            .onTapGesture {
                                stateManager.expandPlayer()
                            }
                        
                        ListeningControl()
                    }
                    .offset(y: Self.kMiniPlayerOffet)
                    .padding(.horizontal, 12)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
        } else {
            TabView(selection: $selectedTab) {
                ForEach(AppTab.allCases) { tab in
                    TabContentView(tab, Self.kTabContentBottomOffset)
                        .tabItem {
                            TabLabel(for: tab)
                        }
                        .tag(tab)
                }
            }
            .overlay(alignment: .bottom) {
                HStack {
                    MiniPlayerViewWithBackground()
                        .onTapGesture {
                            stateManager.expandPlayer()
                        }
                    
                    ListeningControl()
                }
                .offset(y: Self.kMiniPlayerOffet)
                .padding(.horizontal, 12)
            }
            .ignoresSafeArea(.keyboard, edges: .all)
        }
    }
    
    @available(iOS 18.0, *)
    @ViewBuilder
    private func iOS18TabBarView(_ safeAreaBottomPadding: CGFloat = 0) -> some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                Tab(value: tab) {
                    TabContentView(tab, safeAreaBottomPadding)
                } label: {
                    TabLabel(for: tab)
                }
            }
        }
        .defaultAdaptableTabBarPlacement(.tabBar)
    }
    
    @ViewBuilder
    private func TabContentView(_ tab: AppTab, _ safeAreaBottomPadding: CGFloat = 0) -> some View {
        NavigationStack {
            Group {
                switch tab {
                    case .news:
                        NewsTabView()
                    case .stations:
                        StationsScreen()
                    case .saved:
                        SavedEngagementsScreen()
                    case .turls:
                        EngagementHistoryScreen()
                    case .settings:
                        SettingsScreen()
                }
            }
            .safeAreaPadding(.bottom, safeAreaBottomPadding)
        }
    }
    
    @ViewBuilder
    private func TabLabel(for tab: AppTab) -> some View {
        Label {
            Text(tab.title)
        } icon: {
            Image(systemName: tab.icon)
                .environment(\.symbolVariants, selectedTab == tab ? .fill : .none)
        }
    }
    
    @ViewBuilder
    private func MiniPlayerViewWithBackground() -> some View {
        MiniPlayerView()
            .background(content: {
                ZStack {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .fill(.background)
                        .padding(1.2)
                }
                .compositingGroup()
            })
    }
    
    @ViewBuilder
    private func ListeningControl() -> some View {
        Button {
            stateManager.switchListening()
        } label: {
            if #available(iOS 26.0, *) {
                ListeningControlContent()
                    .glassEffect(.regular.interactive())
            } else {
                ListeningControlContent()
                    .background {
                        ZStack {
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(.gray.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .fill(.background)
                                .padding(1.2)
                        }
                        .compositingGroup()
                    }
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder private func ListeningControlContent() -> some View {
        Image(stateManager.isListening
              //.customMicrophoneFillBadgeWaveform: .customMicrophoneBadgePause)
              ? "waveform.badge.magnifyingglass"
              : "speaker.zzz.fill")
            .symbolEffect(.pulse, isActive: stateManager.isListening)
            .font(.title2)
            .foregroundStyle(stateManager.isListening ? Color.accentColor : .secondary)
            .environment(\.symbolVariants, stateManager.isListening ? .fill : .none)
            .padding(16)
            .contentShape(Rectangle())
    }
}
