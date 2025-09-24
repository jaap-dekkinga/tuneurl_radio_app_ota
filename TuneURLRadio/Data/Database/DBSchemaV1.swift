import Foundation
import SwiftData

enum DBSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [SavedEngagement.self, HistoryEngagement.self]
    }
    
    @Model
    final class SavedEngagement {
        var id: UUID
        var createAt: Date
        
        var engagementId: Int
        var engagementType: String
        var engagementName: String?
        var engagementDescription: String?
        var engagementInfo: String?
        
        var heardAt: Date
        var sourceStationId: Int?
        
        init(
            id: UUID,
            engagementId: Int,
            engagementType: String,
            engagementName: String?,
            engagementDescription: String?,
            engagementInfo: String?,
            heardAt: Date,
            sourceStationId: Int?,
            createAt: Date,
        ) {
            self.id = id
            self.createAt = createAt
            
            self.engagementId = engagementId
            self.engagementType = engagementType
            self.engagementName = engagementName
            self.engagementDescription = engagementDescription
            self.engagementInfo = engagementInfo
            
            self.heardAt = heardAt
            self.sourceStationId = sourceStationId
        }
    }
    
    @Model
    final class HistoryEngagement {
        var id: UUID
        var createAt: Date
        
        var engagementId: Int
        var engagementType: String
        var engagementName: String?
        var engagementDescription: String?
        var engagementInfo: String?
        
        var heardAt: Date
        var sourceStationId: Int?
        
        init(
            id: UUID,
            engagementId: Int,
            engagementType: String,
            engagementName: String?,
            engagementDescription: String?,
            engagementInfo: String?,
            heardAt: Date,
            sourceStationId: Int?,
            createAt: Date
        ) {
            self.id = id
            self.createAt = createAt
            
            self.engagementId = engagementId
            self.engagementType = engagementType
            self.engagementName = engagementName
            self.engagementDescription = engagementDescription
            self.engagementInfo = engagementInfo
            
            self.heardAt = heardAt
            self.sourceStationId = sourceStationId
        }
    }
}
