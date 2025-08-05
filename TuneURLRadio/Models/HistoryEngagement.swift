import Foundation
import SwiftData
import TuneURL

@Model
final class HistoryEngagement {
    @Attribute(.unique) var id: UUID
    
    var engagementType: String
    var engagementName: String?
    var engagementDescription: String?
    var engagementInfo: String?
    
    var saveDate: Date
    var sourceStationId: Int?
    
    init(match: TuneURL.Match, stationId: Int? = nil) {
        id = UUID()
        engagementName = match.name
        engagementDescription = match.description
        engagementType = match.type
        engagementInfo = match.info
        
        saveDate = Date.now
        sourceStationId = stationId
    }
    
    init(
        type: String,
        name: String? = nil,
        description: String? = nil,
        info: String? = nil,
        stationId: Int? = nil
    ) {
        id = UUID()
        self.engagementType = type
        self.engagementName = name
        self.engagementDescription = description
        self.engagementInfo = info
        
        saveDate = Date.now
        self.sourceStationId = stationId
    }
}

extension HistoryEngagement {
    
    var engagementURL: URL? {
        guard let info = engagementInfo else { return nil }
        return URL(string: info, encodingInvalidCharacters: false)
    }
    
    var engagement: Engagement {
        Engagement(
            type: engagementType,
            name: engagementName,
            description: engagementDescription,
            info: engagementInfo
        )
    }
}
