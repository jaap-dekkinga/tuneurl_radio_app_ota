import SwiftUI

@Observable
class CurrentPlayManager {
    
    static let shared = CurrentPlayManager()
    
    var expandedPlayer = false
    var currentStation: StationModel?
    
    var isPlaying = false
    
    func expandPlayer() {
//        guard currentStation != nil else { return }
        expandedPlayer = true
    }
    
    func switchStation(to station: StationModel) {
        currentStation = station
    }
    
    func switchPlayback() {
        guard currentStation != nil else { return }
        isPlaying.toggle()
        // TODO: add logic to switch between play and stop
    }
}
