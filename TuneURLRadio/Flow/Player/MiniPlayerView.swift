import SwiftUI
import Kingfisher

struct MiniPlayerView: View {
    
    @Environment(StateManager.self) private var stateManager
    
    var body: some View {
        HStack(spacing: 15) {
            PlayerInfo(.init(width: 36, height: 36))
            
            Spacer(minLength: 0)

            Button {
                stateManager.switchPlaybackState()
            } label: {
                Image(systemName: stateManager.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .contentShape(.rect)
                    .symbolEffect(.bounce, value: stateManager.isPlaying)
            }
            .padding(.trailing, 10)
            .disabled(stateManager.currentStation == nil)
        }
        .foregroundStyle(stateManager.currentStation == nil ? Color.secondary : Color.primary)
        .padding(12)
    }
    
    @ViewBuilder
    func PlayerInfo(_ size: CGSize) -> some View {
        HStack(spacing: 12) {
            ArtworkView(size: size.width)
            
            if let name = stateManager.currentStation?.name {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            } else {
                Text("Select station to play")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}
