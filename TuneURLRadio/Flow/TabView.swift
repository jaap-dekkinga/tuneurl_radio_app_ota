import SwiftUI
import Kingfisher

struct RootView: View {
    
    static let kMiniPlayerOffet = -54.0
    static let kTabContentBottomOffset = 60.0
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(CurrentPlayManager.self) private var currentPlayManager
    
    @SceneStorage("selectedTab")
    private var selectedTab: AppTab = .stations
    
    @Namespace private var animation
    
    var body: some View {
        @Bindable var currentPlayManager = currentPlayManager
        Group {
            //        if #available(iOS 26, *) {
            //            iOS18TabBarView
            //                .tabBarMinimizeBehavior(.onScrollDown)
            //                .tabViewBottomAccessory {
            //                    MiniPlayerView()
            //                        .matchedTransitionSource(id: AnimationID.playerView.rawValue, in: animation)
            //                        .onTapGesture {
            //                            expandMiniPlayer.toggle()
            //                        }
            //                }
            //        }
            if #available(iOS 18.0, *) {
                iOS18TabBarView(Self.kTabContentBottomOffset)
                    .overlay(alignment: .bottom) {
                        MiniPlayerViewWithBackground()
                            .matchedTransitionSource(id: AnimationID.playerView.rawValue, in: animation)
                            .onTapGesture {
                                currentPlayManager.expandPlayer()
                            }
                            .offset(y: Self.kMiniPlayerOffet)
                            .padding(.horizontal, 12)
                    }
                    .ignoresSafeArea(.keyboard, edges: .all)
            } else {
                TabView(selection: $selectedTab) {
                    ForEach(AppTab.allCases, id: \.hashValue) { tab in
                        TabContentView(tab, Self.kTabContentBottomOffset)
                            .tabItem {
                                TabLabel(for: tab)
                            }
                            .tag(tab)
                    }
                }
                .overlay(alignment: .bottom) {
                    MiniPlayerViewWithBackground()
                        .onTapGesture {
                            currentPlayManager.expandPlayer()
                        }
                        .offset(y: Self.kMiniPlayerOffet)
                        .padding(.horizontal, 12)
                }
                .ignoresSafeArea(.keyboard, edges: .all)
            }
        }
        .fullScreenCover(isPresented: $currentPlayManager.expandedPlayer) {
            PlayerScreen(animation: animation)
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
                    case .stations:
                        StationsScreen()
                    case .saved:
                        SavedScreen()
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
}
