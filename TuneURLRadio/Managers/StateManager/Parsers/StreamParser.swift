import Foundation
import TuneURL
import AudioStreaming

fileprivate let log = Log(label: "StreamParser")

class StreamParser: NSObject {
    
    // MARK: - Public props
    var onMatchDetected: (@MainActor (Match) -> Void)?
    
    // MARK: - Private props
    private var settings = SettingsStore.shared
    
    private let currentPlayer: AudioPlayer
    private let streamDetector: StreamDetector
    
    private var lastMatch: Match?
    private var lastMatchTime: Date?
    
    override init() {
        currentPlayer = AudioPlayer()
        currentPlayer.volume = 0.001
        
        let triggerURL = Bundle.main.url(forResource: "trigger_sound", withExtension: "mp3")!
        streamDetector = StreamDetector(triggerURL)
        super.init()
        
        let parse = FilterEntry(name: "detector") {[weak self] buffer, _ in
            self?.streamDetector.append(buffer)
        }
        currentPlayer.frameFiltering.add(entry: parse)
        
        streamDetector.matchCallback = {[weak self] _ in
            guard let self else { return }
            
            do {
                // TEST MODE: Always return a hardcoded coupon Match when local trigger detection fires.
                // The server response (the `match` parameter) is intentionally ignored.
                // To restore production behavior: uncomment the block below and delete the test block.
                let testMatchData: [String: Any] = [
                    "id": 999001,
                    "type": "coupon",
                    "name": "KSAL Pilot Coupon",
                    "description": "Test coupon — local trigger detected",
                    "info": "https://assets.zyrosite.com/Yg2OE4oyabSqG583/ksal_pilot_coupon-5TuQwblD5TseTfb1.png",
                    "matchPercentage": 100
                ]
                
                let jsonData = try JSONSerialization.data(withJSONObject: testMatchData)
                let testMatch = try JSONDecoder().decode(Match.self, from: jsonData)
                testMatch.fingerprintVersion = "V2-TEST"
                
                DispatchQueue.main.async {
                    self.processMatch(testMatch, isTestMode: true)
                }
            } catch {
                log.write("Error creating test match: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Private funcs
    private func processMatch(_ match: Match, isTestMode: Bool) {
        // Suppress duplicate matches within 10s (same dedup logic as production)
        if let lastMatch = self.lastMatch,
           lastMatch.id == match.id,
           let lastMatchTime = self.lastMatchTime,
           abs(lastMatchTime.timeIntervalSinceNow) < 10 {
            let mode = isTestMode ? "test coupon" : "recognition"
            log.write("Duplicate \(mode) — suppressed")
            return
        }
        
        let modeDescription = isTestMode ? "(TEST COUPON)" : "(fingerprint: \(match.fingerprintVersion ?? "unknown"))"
        log.write("Stream Match Detected \(modeDescription)\n\(match.prettyDescription())")
        
        self.lastMatch = match
        self.lastMatchTime = Date.now
        self.onMatchDetected?(match)
    }
    
    // MARK: - Public funcs
    func start(streamURL: URL) {
        currentPlayer.stop(clearQueue: true)
        currentPlayer.play(url: streamURL)
    }
    
    func stop() {
        currentPlayer.stop(clearQueue: true)
        streamDetector.reset()
        
        lastMatch = nil
        lastMatchTime = nil
    }
}

extension Match: @retroactive Equatable {
    
    public static func ==(_ lhs: Match, _ rhs: Match) -> Bool {
        lhs.id == rhs.id &&
        lhs.info == rhs.info &&
        lhs.name == rhs.name &&
        lhs.description == rhs.description &&
        lhs.type == rhs.type
    }
}
