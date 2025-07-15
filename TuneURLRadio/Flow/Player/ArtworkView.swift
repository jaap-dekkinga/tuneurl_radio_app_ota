import SwiftUI
import Kingfisher

struct ArtworkView: View {
    
    @Environment(StateManager.self) private var stateManager
    
    let size: Double
    @Binding var artworkImage: UIImage?
    
    init(
        size: Double,
        artworkImage: Binding<UIImage?> = .constant(nil)
    ) {
        self.size = size
        self._artworkImage = artworkImage
    }
    
    var body: some View {
        VStack {
            if let currentArtworkURL = stateManager.currentArtworkURL {
                KFImage(currentArtworkURL)
                    .onSuccess { result in
                        artworkImage = result.image
                    }
                    .resizable()
                    .scaledToFit()
            } else {
                Image(.stationLogo)
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: min(size / 4, 20)))
        .animation(.easeInOut(duration: AnimationID.PlayerArtworkUpdateDuration), value: stateManager.currentArtworkURL)
    }
}
