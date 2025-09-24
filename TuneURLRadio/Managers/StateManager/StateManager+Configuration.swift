import Foundation
import TuneURL
import FRadioPlayer
import MediaPlayer
import AVFoundation

extension StateManager {
    
    func configure() {
        configureRadioPlayer()
        configureCommandCenter()
        configureTuneURL()
        
        startListening()
    }
    
    private func configureRadioPlayer() {
        FRadioPlayer.shared.isAutoPlay = false
        FRadioPlayer.shared.enableArtwork = true
        FRadioPlayer.shared.artworkAPI = iTunesAPI(artworkSize: 600)
    }
    
    func prepareAndActivateAudioSession() {
        print("➡️ State - Prepare and Activate Player Audio Session")
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(0.1)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error {
            print("audioSession could not be activated: \(error.localizedDescription)")
        }
    }
    
    func deactivateAudioSession() {
        print("➡️ State - Deactivate Player Audio Session")
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    private func configureCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { event in
            StateManager.shared.play()
            return .success
        }
        
        commandCenter.stopCommand.addTarget { event in
            StateManager.shared.stop()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { event in
            StateManager.shared.switchPlaybackState()
            return .success
        }
    }
    
    private func configureTuneURL() {
        guard let url = Bundle.main.url(forResource: "trigger_sound", withExtension: "mp3") else {
            return
        }
        Detector.setTrigger(url)
        Listener.setTrigger(url)
    }
}
