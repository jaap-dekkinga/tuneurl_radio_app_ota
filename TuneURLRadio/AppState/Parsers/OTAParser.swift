import Foundation
import TuneURL

class OTAParser {
    
    // MARK: - Public props
    var matchThreshold = 30
    var onMatchDetected: ((Match) -> Void)?
    
    // MARK: - Private props
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        Listener.startListening { [weak self] match in
            guard
                let self,
                  match.matchPercentage >= matchThreshold
            else { return }
            #if DEBUG
            print("Detected OTA Match:\n\(match.prettyDescription())")
            #endif
            onMatchDetected?(match)
        }
    }
    
    func stop() {
        guard isRunning else { return }
        Listener.stopListening()
        isRunning = false
    }
}
