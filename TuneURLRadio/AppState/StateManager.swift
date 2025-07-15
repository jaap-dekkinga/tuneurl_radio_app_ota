import UIKit
import SwiftUI
import FRadioPlayer
import TuneURL
import MediaPlayer
import Kingfisher

@Observable
class StateManager {
    
    static let shared = StateManager()
    
    // MARK: - Public props
    var expandedPlayer = false
    private(set) var currentStation: Station?
    private(set) var playerState: PlayerState = .offline
    
    private(set) var currentMetadata: FRadioPlayer.Metadata? {
        didSet { updateNowPlayerInfo() }
    }
    private(set) var currentArtworkURL: URL? {
        didSet { updateNowPlayerArtwork() }
    }
    
    private(set) var isPlaying = false
    private(set) var isListening = false
    
    var currentMatch: TuneURL.Match?
    
    // MARK: - Private props
    @ObservationIgnored private let player = FRadioPlayer.shared
    @ObservationIgnored private let otaParser = OTAParser()
    @ObservationIgnored private let streamParser = StreamParser()
    
    var sleepDeadline: Date?
    @ObservationIgnored var sleepTimer: Timer?
    
    @ObservationIgnored var audioSystemResetObserver: Any?
    
    private init() {
        player.addObserver(self)
        
        otaParser.onMatchDetected = { [weak self] match in
            print("➡️ State - On OTA Match")
            guard self?.currentMatch == nil else { return }
            self?.currentMatch = match
        }
        
        streamParser.onMatchDetected = { [weak self] match in
            print("➡️ State - On Stream Match")
            guard self?.currentMatch == nil else { return }
            self?.currentMatch = match
        }
    }
    
    // MARK: - Public Getter
    var hasMetadata: Bool {
        currentMetadata?.trackName != nil || currentMetadata?.artistName != nil
    }
    
    var currentPlayingStation: Station? {
        isPlaying ? currentStation : nil
    }
    
    // MARK: - Station and Player UI State
    func expandPlayer() {
        guard currentStation != nil else { return }
        expandedPlayer = true
    }
    
    func switchStation(to station: Station) {
        print("➡️ State - Switch Station to \(station.name)")
        currentMetadata = nil
        currentArtworkURL = station.imageURL
        
        currentStation = station
        expandedPlayer = true
        
        player.radioURL = station.streamURL
        play()
    }
    
    // MARK: - Playback Control funcs
    func play() {
        print("➡️ State - Play")
        stopListening()
        
        prepareAndActivateAudioSession()
        
        isPlaying = true
        player.play()
        
        if let currentStation {
            streamParser.start(streamURL: currentStation.streamURL)
        }
    }
    
    func stop() {
        print("➡️ State - Stop")
        
        isPlaying = false
        player.stop()
        streamParser.stop()
        deactivateAudioSession()
        
        startListening()
    }
 
    func switchPlaybackState() {
        guard currentStation != nil else { return }
        print("➡️ State - Switch Playback State")
        
        if player.isPlaying {
            stop()
        } else {
            play()
        }
    }
    
    // MARK: - Listening OTA
    func startListening() {
        guard !isListening else { return }
        print("➡️ State - Start Listening")
        isListening = true
        
        // TODO: need to optimize inside TuneURL and use DispatchQueue
        otaParser.start()
    }
    
    func stopListening() {
        guard isListening else { return }
        print("➡️ State - Stop Listening")
        isListening = false
        // TODO: need to optimize inside TuneURL and use DispatchQueue
        otaParser.stop()
    }
    
    func switchListening() {
        print("➡️ State - Switch Listening")
        if player.isPlaying {
            stop()
        } else if isListening {
            stopListening()
        } else {
            startListening()
        }
    }
}

extension StateManager: FRadioPlayerObserver {
    
    func radioPlayer(_ player: FRadioPlayer, playerStateDidChange state: FRadioPlayer.State) {
        print("➡️ State - Player State Changed: \(state)")
        playerState = switch state {
            case .urlNotSet: .offline
            case .readyToPlay: player.isPlaying ? .live : .loading
            case .loading: .loading
            case .loadingFinished: player.isPlaying ? .live : .loading
            case .error: .offline
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, playbackStateDidChange state: FRadioPlayer.PlaybackState) {
        print("➡️ State - Playback State Changed: \(state)")
        switch state {
            case .playing:
                isPlaying = true
                playerState = .live
                
            case .paused, .stopped:
                isPlaying = false
                playerState = .offline
        }
    }
    
    func radioPlayer(_ player: FRadioPlayer, metadataDidChange metadata: FRadioPlayer.Metadata?) {
        currentMetadata = metadata
    }
    
    func radioPlayer(_ player: FRadioPlayer, artworkDidChange artworkURL: URL?) {
        currentArtworkURL = artworkURL ?? currentStation?.imageURL
    }
}

// MARK: - Nested Types
extension StateManager {
    
    enum PlayerState {
        case loading
        case live
        case offline
        
        var title: LocalizedStringKey {
            switch self {
                case .loading: "LOADING..."
                case .live: "LIVE"
                case .offline: "OFFLINE"
            }
        }
    }
}
