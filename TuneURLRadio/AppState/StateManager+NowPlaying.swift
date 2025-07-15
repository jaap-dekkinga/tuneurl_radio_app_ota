import Foundation
import MediaPlayer
import Kingfisher

extension StateManager {
    
    // MARK: - Now Plaing Info
    func updateNowPlayerArtwork() {
        guard let artworkURL = currentArtworkURL else {
            return
        }
        
        print("➡️ State - Update Now Playing Artwork")
        
        KingfisherManager.shared.retrieveImage(with: artworkURL) { result in
            guard case .success(let imageResult) = result else { return }
            let image = imageResult.image
            
            DispatchQueue.main.async {
                var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
                
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                    boundsSize: image.size,
                    requestHandler: { _ in return image }
                )
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    func updateNowPlayerInfo() {
        print("➡️ State - Update Now Playing Info")
        
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        if let artistName = currentMetadata?.artistName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        }
        if let trackName = currentMetadata?.trackName {
            nowPlayingInfo[MPMediaItemPropertyTitle] = trackName
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}
