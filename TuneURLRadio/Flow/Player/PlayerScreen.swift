import SwiftUI
import LinkPresentation

struct PlayerScreen: View {

    @Environment(DataStore.self) private var dataStore
    @Environment(StateManager.self) private var stateManager
    
    @State private var artworkImage: UIImage? = UIImage.stationLogo
    @State private var socialLinkMetadata: LPLinkMetadata?
    
    let animation: Namespace.ID
    
    var body: some View {
        ZStack {
            PlayerBlurBackground(
                displayImage: artworkImage
            )
            
            ScrollView {
                if #available(iOS 18.0, *) {
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color.white.secondary)
                            .frame(width: 52, height: 4)
                        VStack(spacing: 0) {
                            MainInfo()
                                .navigationTransition(.zoom(sourceID: AnimationID.playerView.rawValue, in: animation))
                            SecondaryContent()
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 0) {
                        MainInfo()
                        SecondaryContent()
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .animation(.linear(duration: 0.3), value: stateManager.hasMetadata)
        }
    }
    
    @ViewBuilder
    private func MainInfo() -> some View {
        VStack(spacing: 0) {
            ArtworkView(
                size: 260,
                artworkImage: $artworkImage
            )
            .shadow(color: Color.black.opacity(0.3), radius: 24)
            .scaleEffect(stateManager.isPlaying ? 1.0 : 0.8, anchor: .center)
            .animation(.spring(bounce: 0.6), value: stateManager.isPlaying)
            .padding(.bottom, 24)
            
            VStack(spacing: 16) {
                Text(stateManager.currentStation?.name ?? "-")
                    .font(.title2.weight(.medium))
                
                VStack {
                    if stateManager.hasMetadata {
                        VStack(alignment: .leading, spacing: 0) {
                            if let title = stateManager.currentMetadata?.trackName {
                                Text(title)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                            }
                            
                            if let subtitle = stateManager.currentMetadata?.artistName {
                                Text(subtitle)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 32)
                            .transition(.opacity)
                    }
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.bottom)
    }
    
    @ViewBuilder
    private func SecondaryContent() -> some View {
        VStack {
            PlayerStatusLineView(state: stateManager.playerState)
            
            Button {
                stateManager.switchPlaybackState()
            } label: {
                Image(systemName: stateManager.isPlaying ? "stop.fill" : "play.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
                    .symbolEffect(.bounce, value: stateManager.isPlaying)
            }
            .padding(.vertical, 52)
            
            VolumeSliderView()
                .frame(height: 34)
                .frame(maxWidth: .infinity)
            
            ControlButtons()
                .padding(.top, 32)
                .padding(.bottom, 24)
            
            if let socialURL = stateManager.currentStation?.socialURL {
                SocialsView(socialURL)
            }
        }
        .foregroundStyle(.white)
        .lineLimit(1)
    }
    
    @ViewBuilder
    private func ControlButtons() -> some View {
        HStack {
            SleepTimerButton()
            
            Spacer()
            
            AirPlayView()
                .frame(width: 44, height: 44)
            
            Spacer()
            
            ShareLink(
                item: stateManager.currentStation?.socialURL ?? URL(string: "https://www.tuneurl.com/")!
            ) {
                Label("Share", systemImage: "square.and.arrow.up")
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background {
                        Capsule()
                            .fill(.primary.tertiary)
                    }
            }
            .opacity(stateManager.currentStation?.socialURL == nil ? 0 : 1)
        }
    }
    
    @ViewBuilder
    private func SocialsView(_ socialURL: URL) -> some View {
        VStack {
            Text("Explore Our Socials")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            URLPreview(
                previewURL: socialURL,
                linkMetadata: $socialLinkMetadata
            )
            .id(socialURL)
            .frame(maxHeight: 180)
            .transition(.scale(scale: 0.0, anchor: .top).combined(with: .opacity))
        }.opacity(socialLinkMetadata != nil ? 1 : 0)
    }
}

#Preview {
    @Previewable @Namespace var animation
    PlayerScreen(animation: animation)
        .withPreviewEnv()
        .onAppear {
            StateManager.shared.switchStation(to: DataStore.shared.stations[3])
        }
}
