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
    
    
    // MARK: - Instance
    static let shared = UserSettings()
    private init() {}
}
