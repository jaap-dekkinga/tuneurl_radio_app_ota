import Foundation

enum EngagementType: String, Codable {
    case unknown
    case openPage = "open_page"
    case savePage = "save_page"
    case phone
    case sms
    case coupon
    case poll
    case api = "api_call"
}
