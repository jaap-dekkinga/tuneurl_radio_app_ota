import Foundation
import TuneURL

struct Engagement: Codable, Identifiable {
    let id: Int
    let rawType: String
    let type: EngagementType
    let name: String?
    let description: String?
    let info: String?
    
    let heardAt: Date
    let sourceStationId: Int?
    
    init(
        match: Match,
        heardAt: Date,
        sourceStationId: Int?
    ) {
        self.id = match.id
        self.rawType = match.type
        self.type = EngagementType(rawValue: match.type.lowercased()) ?? .unknown
        self.name = match.name
        self.description = match.description
        self.info = match.info
        self.heardAt = heardAt
        self.sourceStationId = sourceStationId
    }
    
    init(
        id: Int,
        type: String,
        name: String?,
        description: String?,
        info: String?,
        heardAt: Date,
        sourceStationId: Int?
    ) {
        self.id = id
        self.rawType = type
        self.type = EngagementType(rawValue: type.lowercased()) ?? .unknown
        self.name = name
        self.description = description
        self.info = info
        self.heardAt = heardAt
        self.sourceStationId = sourceStationId
    }
    
    var isPage: Bool {
        type == .openPage || type == .savePage
    }
    
    var canSave: Bool {
        isPage || type == .coupon
    }
    
    /// The server's link, only if it is a safe https URL (see SafeLinks).
    var handleURL: URL? {
        SafeLinks.webURL(info)
    }

    /// The server's phone number, only if it looks like a phone number.
    var phoneNumber: String? {
        SafeLinks.phoneNumber(info)
    }
}
