import Foundation
import SwiftData

typealias SavedEngagement = DBSchemaV1.SavedEngagement

extension SavedEngagement {
    
    convenience init(engagement: Engagement) {
        self.init(
            id: UUID(),
            engagementId: engagement.id,
            engagementType: engagement.rawType,
            engagementName: engagement.name,
            engagementDescription: engagement.description,
            engagementInfo: engagement.info,
            heardAt: engagement.heardAt,
            sourceStationId: engagement.sourceStationId,
            createAt: Date.now
        )
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
            id: engagementId,
            type: engagementType,
            name: engagementName,
            description: engagementDescription,
            info: engagementInfo,
            heardAt: heardAt,
            sourceStationId: sourceStationId
        )
    }
}
