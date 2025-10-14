import UIKit
import TuneURL
import Sharing

private let log = Log(label: "ReportingManager")

class ReportingManager {
    
    static let shared = ReportingManager()
    
    @Shared(.appStorage("ReportingUserID"))
    private var userId: String = UUID().uuidString
    
    @Shared(.fileStorage(.cachesDirectory.appending(component: "reporting_cache")))
    private var reportingCache: [ReportModel] = []
    
    private let client: API
    private var sendingChunk: [ReportModel]?
    
    private let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        let timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "YYYY-MM-dd'T'HHmm"
        dateFormatter.timeZone = timeZone
        return dateFormatter
    }()
    
    private init() {
        let baseURL = URL(string: "https://65neejq3c9.execute-api.us-east-2.amazonaws.com")!
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        
        client = API(
            baseURL: baseURL,
            encoder: encoder
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationNotifications(_:)),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationNotifications(_:)),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    func report(_ action: ReportAction) {
        log.write("Reporting action: \(action.actionValue) for matchId: \(action.matchId.description)", level: .info)
        
        let model = ReportModel(
            userId: userId.replacingOccurrences(of: "-", with: ""),
            date: action.heardDate,
            matchId: action.matchId,
            action: action.actionValue
        )
        
        $reportingCache.withLock {
            $0.append(model)
        }

        sendReportsIfNeeded()
    }
    
    func sendPendingReports() {
        sendReportsIfNeeded(skipLimit: true)
    }
    
    // MARK: - Private funcs
    @objc private func applicationNotifications(_ notification: Notification) {
        sendReportsIfNeeded(skipLimit: true)
    }
    
    private func sendReportsIfNeeded(skipLimit: Bool = false) {
        guard sendingChunk == nil else { return }
    
        if reportingCache.count >= 5 || skipLimit {
            log.write("Sending \(reportingCache.count) reports", level: .info)
            let reportsToSend = reportingCache
            
            sendingChunk = reportsToSend
            defer { sendingChunk = nil }
            
            Task {
                do {
                    var data = "[\n"
                    for report in reportsToSend { 
                        data += """
{
"UserID": "\(report.userId.replacingOccurrences(of: "-", with: ""))",
"Date": "\(dateFormatter.string(from: report.date))",
"TuneURL_ID": "\(report.matchId)",
"Interest_action": "\(report.action.lowercased())"
}
"""
                        
                        if report.id != reportsToSend.last?.id {
                            data += ",\n"
                        }
                    }
                    data += "\n]\n"
 
                    try await client.post("/interests", params: data, headers: ["Content-Type": "text/plain"])
                    let idsToRemove = Set(reportsToSend.map { $0.id })
                    $reportingCache.withLock {
                        $0.removeAll { idsToRemove.contains($0.id) }
                    }
                    log.write("Successfully sent \(reportsToSend.count) reports", level: .info)
                } catch {
                    if error.localizedDescription.contains("Duplicate entry") {
                        let idsToRemove = Set(reportsToSend.map { $0.id })
                        $reportingCache.withLock {
                            $0.removeAll { idsToRemove.contains($0.id) }
                        }
                    }
                    log.write("Failed to send reports: \(error)", level: .error)
                }
            }
        }
    }
}

fileprivate struct ReportModel: Codable {
    let id: UUID = UUID()
    let userId: String
    let date: Date
    let matchId: Int
    let action: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "UserID"
        case date = "Date"
        case matchId = "TuneURL_ID"
        case action = "Interest_action"
    }
}

fileprivate extension ReportAction {
    
     var actionValue: String {
        switch self {
            case .heard: "heard"
            case .interested: "interested"
            case .acted: "acted"
            case .shared: "shared"
        }
    }
    
    var matchId: Int {
        switch self {
            case .heard(let model): model.id
            case .interested(let model): model.id
            case .acted(let model): model.id
            case .shared(let model): model.id
        }
    }
    
    var heardDate: Date {
        switch self {
            case .heard(let model): model.heardAt
            case .interested(let model): model.heardAt
            case .acted(let model): model.heardAt
            case .shared(let model): model.heardAt
        }
    }
}
