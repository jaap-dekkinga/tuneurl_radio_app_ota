import SwiftUI
import Kingfisher

struct CouponEngagementView: View {
    let engagement: Engagement
    
    var body: some View {
        if let handleURL = engagement.handleURL {
            KFImage(handleURL)
                .resizable()
                .aspectRatio(contentMode: .fit)
            Spacer()
        } else {
            FailedLoadContentView()
        }
    }
}
