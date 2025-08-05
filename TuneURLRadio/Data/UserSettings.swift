import Foundation
import Sharing

@Observable
class UserSettings {
    
    // MARK: - Settings
    @ObservationIgnored
    @Shared(.appStorage("ota_match_threshold"))
    var otaMatchThreshold: Int = 10
    
    @ObservationIgnored
    @Shared(.appStorage("stream_match_threshold"))
    var streamMatchThreshold: Int = 10
    
    @ObservationIgnored
    @Shared(.appStorage("engagement_display_mode"))
    var engagementDisplayMode: EngagementDisplayMode = .modal
    
    @ObservationIgnored
    @Shared(.appStorage("store_all_engagements"))
    var storeAllEngagementsHistory: Bool = false
    
    
    // MARK: - Instance
    static let shared = UserSettings()
    private init() {}
}
