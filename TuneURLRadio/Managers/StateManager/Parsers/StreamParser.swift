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
        
        streamDetector.matchCallback = {[weak self] match in
            guard let self else { return }
            if match.matchPercentage >= self.settings.streamMatchThreshold {
                DispatchQueue.main.async {
                    if let lastMatch = self.lastMatch,
                       lastMatch.id == match.id,
                       let lastMatchTime = self.lastMatchTime,
                       abs(lastMatchTime.timeIntervalSinceNow) < 10 {
                        log.write("Duplicate recognition:\n\tPrev Time: \(lastMatchTime)\n\tMatch: \(lastMatch.prettyDescription())\n\tCurrent Time:\(Date.now)\n\tCurrent Match: \(match.prettyDescription())\n\n")
                        #if DEBUG
                        fatalError()
                        #endif
                    }
                    
                    self.lastMatch = match
                    self.lastMatchTime = Date.now
                    self.onMatchDetected?(match)
                }
            } else {
                log.write("Not found match with sufficient match percentage: \(settings.streamMatchThreshold).")
            }
        }
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
