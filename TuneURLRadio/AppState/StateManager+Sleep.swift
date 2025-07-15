import Foundation

extension StateManager {
    
    // MARK: - Sleep Timer
    func nextSleepDate() -> Date? {
        sleepDeadline
    }
    
    func setSleepTimer(for interval: TimeInterval?) {
        sleepTimer?.invalidate()
        sleepTimer = nil
        
        if let interval {
            let newInterval = interval + 1
            sleepDeadline = Date(timeIntervalSinceNow: newInterval)
            sleepTimer = Timer.scheduledTimer(
                withTimeInterval: newInterval,
                repeats: false,
                block: { [weak self] _ in
                    guard let self else { return }
                    sleepDeadline = nil
                    if isPlaying {
                        stop()
                    }
                    if isListening {
                        switchListening()
                    }
                })
        } else {
            sleepDeadline = nil
        }
    }
}
