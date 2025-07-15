import Foundation
import TuneURL

enum EngagementType: String {
    case unknown
    case openWebPage = "open_page"
    case saveWebPage = "save_page"
    case phone
    case sms
    case coupon
    case poll
}

struct Engagement {
    let type: EngagementType
    let name: String?
    let description: String?
    let info: String?
    
    init(_ match: Match) {
        self.type = EngagementType(rawValue: match.type) ?? .unknown
        self.name = match.name
        self.description = match.description
        self.info = match.info
    }
    
    init(
        type: String,
        name: String? = nil,
        description: String? = nil,
        info: String? = nil
    ) {
        self.type = EngagementType(rawValue: type) ?? .unknown
        self.name = name
        self.description = description
        self.info = info
    }
}
