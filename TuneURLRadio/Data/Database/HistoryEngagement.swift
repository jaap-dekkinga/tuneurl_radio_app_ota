import Foundation
import SwiftData
import TuneURL

typealias HistoryEngagement = DBSchemaV1.HistoryEngagement

extension HistoryEngagement {

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

extension HistoryEngagement {
    
    var engagementURL: URL? {
        SafeLinks.webURL(engagementInfo)
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

