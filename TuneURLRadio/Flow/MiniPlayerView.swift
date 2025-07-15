import SwiftUI
import Kingfisher

struct MiniPlayerView: View {
    
    @Environment(CurrentPlayManager.self) private var playManager
    
    var body: some View {
        HStack(spacing: 15) {
            PlayerInfo(.init(width: 36, height: 36))
            
            Spacer(minLength: 0)

            Button {
                playManager.switchPlayback()
            } label: {
                Image(systemName: playManager.isPlaying ? "stop.fill" : "play.fill")
                    .font(.title3)
                    .contentShape(.rect)
                    .symbolEffect(.bounce, value: playManager.isPlaying)
            }
            .padding(.trailing, 10)
        }
        .foregroundStyle(Color.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
    
    @ViewBuilder
    func PlayerInfo(_ size: CGSize) -> some View {
        HStack(spacing: 12) {
            Group {
                if let station = playManager.currentStation {
                    if let imageURL = station.imageURL {
                        KFImage(imageURL)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image(.stationLogo)
                            .resizable()
                            .scaledToFit()
                    }
                } else {
                    Rectangle()
                        .fill(Color(uiColor: .systemGray6))
                }
            }
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: size.height / 4))
            
            if let name = playManager.currentStation?.name {
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
