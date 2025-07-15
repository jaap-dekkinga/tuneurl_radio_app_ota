import SwiftUI
import Kingfisher
import TuneURL

struct RootView: View {
    
    @Environment(StateManager.self) private var stateManager
    
    @Namespace private var animation
    
    var body: some View {
        @Bindable var state = stateManager
        TabBarView(animationID: animation)
            .fullScreenCover(isPresented: $state.expandedPlayer) {
                PlayerScreen(animation: animation)
            }
    }
}
