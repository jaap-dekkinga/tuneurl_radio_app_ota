import Foundation
import MediaPlayer
import Kingfisher

extension StateManager {
    
    // MARK: - Now Plaing Info
    func updateNowPlayerArtwork() {
        guard let artworkURL = currentArtworkURL else {
            return
        }
        
        KingfisherManager.shared.retrieveImage(with: artworkURL) { result in
            guard case .success(let imageResult) = result else { return }
            let image = imageResult.image
            
            DispatchQueue.main.async {
                guard
                    var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo,
                    !nowPlayingInfo.isEmpty
                else { return }
                
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                    boundsSize: image.size,
                    requestHandler: { _ in return image }
                )
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            }
        }
    }
    
    func updateNowPlayerInfo() {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [String: Any]()
        if let artistName = currentMetadata?.artistName {
            nowPlayingInfo[MPMediaItemPropertyArtist] = artistName
        }
        if let trackName = currentMetadata?.trackName {
            nowPlayingInfo[MPMediaItemPropertyTitle] = trackName
        }
        if !nowPlayingInfo.isEmpty {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }
}
