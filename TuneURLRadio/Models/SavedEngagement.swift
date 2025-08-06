import Foundation
import SwiftData

@Model
final class SavedEngagement {
    @Attribute(.unique) var id: UUID
    
    var engagementType: String
    var engagementName: String?
    var engagementDescription: String?
    var engagementInfo: String?
    
    var saveDate: Date
    var sourceStationId: Int?
    
    init(engagement: Engagement, stationId: Int? = nil) {
        id = UUID()
        engagementName = engagement.name
        engagementDescription = engagement.description
        engagementType = engagement.type.rawValue
        engagementInfo = engagement.info
        
        saveDate = Date.now
        sourceStationId = stationId
    }
}

extension SavedEngagement {
    
    var engagementURL: URL? {
        guard let info = engagementInfo else { return nil }
        return URL(string: info, encodingInvalidCharacters: false)
    }
    
    var isWebEngagement: Bool {
        engagementURL?.absoluteString.hasPrefix("http") ?? false
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
