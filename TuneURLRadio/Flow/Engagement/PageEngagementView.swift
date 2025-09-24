import SwiftUI

struct PageEngagementView: View {
    let engagement: Engagement
    
    var body: some View {
        if let handleURL = engagement.handleURL {
            AppWebView(url: handleURL)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            FailedLoadContentView()
        }
    }
}
