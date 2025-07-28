import Foundation
import TuneURL

fileprivate let log = Log(label: "OTAParser")

class OTAParser {
    
    // MARK: - Public props
    var onMatchDetected: ((Match) -> Void)?
    
    // MARK: - Private props
    private var settings = UserSettings.shared
    private var isRunning = false
    
    func start() {
        guard !isRunning else { return }
        isRunning = true
        log.write("OTA Parser started with match percentage threshold: \(settings.otaMatchThreshold)")
        Listener.startListening { [weak self] match in
            guard
                let self,
                match.matchPercentage >= settings.otaMatchThreshold
            else {
                log.write("OTA Match ignored because of low match percentage\n\(match.prettyDescription())")
                return
            }
            log.write("OTA Match Detected\n\(match.prettyDescription())")
            onMatchDetected?(match)
        }
    }
    
    func stop() {
        guard isRunning else { return }
        Listener.stopListening()
        log.write("OTA Parser stopped")
        isRunning = false
    }
}
