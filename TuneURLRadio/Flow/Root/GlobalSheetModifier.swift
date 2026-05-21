import SwiftUI
import TuneURL

struct GlobalSheetModifier: ViewModifier {
    
    @State var store = GlobalSheetStore.shared
    
    func body(content: Content) -> some View {
        content
            .sheet(item: $store.currentEngagementOffer) { value in
                EngagementOfferScreen(
                    engagement: offer.engagement,
                    autodismiss: offer.autodismiss,
                    interestedAlreadyReported: offer.interestedAlreadyReported
                )
                .withEnv()
                .presentationDetents([.fraction(0.95), .large], selection: .constant(.large))
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.95)))
            }
            .sheet(item: $store.currentSMSComposer) { value in
                SMSComposerView(engagement: value)
                    .withEnv()
                    .presentationDetents([.fraction(0.95), .large], selection: .constant(.large))
                    .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.95)))
            }
    }
}
