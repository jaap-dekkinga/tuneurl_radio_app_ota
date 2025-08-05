import Foundation
import TuneURL

fileprivate let log = Log(label: "StreamParser")

class StreamParser: NSObject {
    
    // MARK: - Public props
    var onMatchDetected: (@MainActor (Match) -> Void)?
    
    // MARK: - Private props
    private let dataTaskQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "stream-parser.data-task.queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .background
        return queue
    }()
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 0
        return URLSession(
            configuration: configuration,
            delegate: self,
            delegateQueue: dataTaskQueue
        )
    }()
    private var currentRequestTask: URLSessionDataTask?
    
    private var currentStreamURL: URL?
    
    private let chunkQueue = DispatchQueue(label: "stream-parser.chunk.queue")
    private var mediaDataChunks = [Data]()
    
    private var parsingWorkItem: DispatchWorkItem?
    private var lastMatch: Match?
    private var lastMatchDate: Date?
    
    private var settings = UserSettings.shared
    
    // MARK: - Public funcs
    func start(streamURL: URL) {
        guard streamURL != currentStreamURL else { return }
        stop()
        
        dataTaskQueue.addOperation { [weak self] in
            log.write("Starting StreamParser with URL: \(streamURL)")
            self?.currentStreamURL = streamURL
            self?.currentRequestTask = self?.session.dataTask(with: streamURL)
            self?.currentRequestTask?.resume()

            self?.scheduleParsingTask()
        }
    }
    
    func stop() {
        dataTaskQueue.addOperation { [weak self] in
            log.write("Stopping StreamParser")
            self?.currentStreamURL = nil
            
            self?.parsingWorkItem?.cancel()
            self?.currentRequestTask?.cancel()
            self?.currentRequestTask = nil
            
            self?.chunkQueue.async(flags: .barrier) { [weak self] in
                self?.mediaDataChunks.removeAll()
            }
        }
    }
    
    // MARK: - Private funcs
    func scheduleParsingTask() {
        let newTask = DispatchWorkItem { [weak self] in
            guard
                let self,
                !self.mediaDataChunks.isEmpty
            else { return }
            
            let data = chunkQueue.sync {
                let combined = self.mediaDataChunks.reduce(Data(), +)
                return combined
            }
            
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("parsing_audio_chunk.mp3")
            do {
                try data.write(to: fileURL)
                
                var parsed = false
                Detector.processAudio(for: fileURL) { [weak self] matches in
                    guard
                        let self,
                        !parsed
                    else { return }
                    parsed = true
                    
                    let uniqueMatches = matches.uniqueBy(key: { $0.id })
    
                    if uniqueMatches.isEmpty {
                        log.write("No matches found in the audio chunk")
                    } else {
                        var logMessage = "Found \(uniqueMatches.count) matches in the audio chunk"
                        for match in uniqueMatches {
                            logMessage += "\n\n\(match.prettyDescription())"
                        }
                        log.write(logMessage)
                    }
                    
                    let bestMatch = uniqueMatches
                        .filter { $0.matchPercentage >= self.settings.streamMatchThreshold }
                        .max(by: { $0.matchPercentage < $1.matchPercentage })
                    
                    if let bestMatch {
                        let elapsedTimeFromLastMatch = abs(self.lastMatchDate?.timeIntervalSinceNow ?? 0)
                        
                        var similarToLastMatch = false
                        if let lastMatch {
                            similarToLastMatch = bestMatch == lastMatch &&
                            (lastMatch.matchPercentage < bestMatch.matchPercentage && elapsedTimeFromLastMatch < 10) ||
                            (elapsedTimeFromLastMatch < 15)
                        }
                        
                        if !similarToLastMatch {
                            log.write("Reporting Match:\n\(bestMatch.prettyDescription())")
                            self.lastMatch = bestMatch
                            self.lastMatchDate = Date()
                            
                            DispatchQueue.main.async {
                                self.onMatchDetected?(bestMatch)
                            }
                        } else {
                            log.write("Match ignored because same match is already reported during last 15 seconds.")
                        }
                    } else {
                        if !uniqueMatches.isEmpty {
                            log.write("Not found match with sufficient match percentage -\(settings.streamMatchThreshold).")
                        }
                    }
                    
                    self.scheduleParsingTask()
                }
            } catch {
                print("Error writing data to file: \(error)")
                self.scheduleParsingTask()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + 3, execute: newTask)
        parsingWorkItem = newTask
    }
}

// MARK: - URLSessionDelegate
extension StreamParser: URLSessionDelegate {
    
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        chunkQueue.async {
            self.mediaDataChunks.append(data)
            while self.mediaDataChunks.reduce(0, { $0 + $1.count }) > 500_000 {
                self.mediaDataChunks.removeFirst()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as? URLError, error.code == .cancelled { return }
        log.write("Stream request failed with error: \(String(describing: error))", level: .error)
        self.stop()
    }
}

// MARK: - URLSessionDataDelegate
extension StreamParser: URLSessionDataDelegate {
    
}

// MARK: - URLSessionTaskDelegate
extension StreamParser: URLSessionTaskDelegate {
    
}

fileprivate extension Array {
    
    func uniqueBy<U: Hashable>(key: (Element) -> U) -> [Element] {
        var seen = Set<U>()
        var result: [Element] = []
        
        for element in self {
            let fieldValue = key(element)
            if !seen.contains(fieldValue) {
                seen.insert(fieldValue)
                result.append(element)
            }
        }
        
        return result
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
