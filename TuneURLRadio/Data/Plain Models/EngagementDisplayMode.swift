import SwiftUI

enum EngagementDisplayMode: String, CaseIterable, Hashable, Sendable {
    case modal
    case notification
    
    var displayName: LocalizedStringKey {
        switch self {
            case .modal: "Modal"
            case .notification: "Notification"
        }
    }
}
