import SwiftUI

@Observable
class GlobalSheetStore {
    
    static let shared = GlobalSheetStore()
    
    var currentEngagementOffer: PresentedEngagementOffer?
    var currentSMSComposer: Engagement?
    
    private init() {}
    
    var isEmpty: Bool {
        currentEngagementOffer == nil && currentSMSComposer == nil
    }
}

struct PresentedEngagementOffer: Identifiable {
    let engagement: Engagement
    let autodismiss: Bool
    
    var id: Int { engagement.id }
}
