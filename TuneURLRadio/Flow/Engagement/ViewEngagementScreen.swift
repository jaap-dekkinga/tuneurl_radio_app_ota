import SwiftUI
import SwiftData
import Kingfisher

private let log = Log(label: "ViewEngagementScreen")

struct ViewEngagementScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(EngagementsStore.self) private var engagementsStore
    
    @State private var savedEngagement: SavedEngagement?
    private let engagement: Engagement
    
    init(savedEngagement: SavedEngagement) {
        self.engagement = savedEngagement.engagement
        self.savedEngagement = savedEngagement
    }
    
    init(historyEngagement: HistoryEngagement) {
        self.engagement = historyEngagement.engagement
        self.savedEngagement = nil
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(engagement.description ?? engagement.name ?? "")
                .font(.title2.weight(.semibold))
                .lineLimit(0)
            
            switch engagement.type {
                case .openPage, .savePage:
                    PageEngagementView(engagement: engagement)
                    
                case .coupon:
                    CouponEngagementView(engagement: engagement)
                    
                case .poll, .sms, .phone, .api, .unknown:
                    Text("Failder to load content.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
            }
            
            HStack {
                if savedEngagement == nil {
                    EngagementActionButton(saveButtonTitle, color: Color.green) {
                        save()
                    }
                } else {
                    EngagementActionButton(deleteButtonTitle, color: Color.red) {
                        delete()
                    }
                }
            }
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
    }
    
    private var saveButtonTitle: LocalizedStringKey {
        switch engagement.type {
            case .coupon: "Save Coupon"
            case .openPage, .savePage, .poll, .sms, .phone, .api, .unknown: "Save"
        }
    }
    
    private var deleteButtonTitle: LocalizedStringKey {
        switch engagement.type {
            case .coupon: "Delete Coupon"
            case .openPage, .savePage, .poll, .sms, .phone, .api, .unknown: "Delete"
        }
    }

    private func save() {
        savedEngagement = engagementsStore.saveForLater(engagement)
    }

    private func delete() {
        guard let entity = savedEngagement else { return }
        engagementsStore.delete(entity)
        savedEngagement = nil
    }
}

#Preview {
    @Previewable @State var show = true
    NavigationStack {
        Button("Show Engagement") {
            show.toggle()
        }
        .sheet(isPresented: $show) {
            ViewEngagementScreen(
                savedEngagement: SavedEngagement(engagement: Engagement(
                    id: 1,
                    type: "open_page",
                    name: "Concert Tickets",
                    description: "Live Nations",
                    info: "https://www.livenation.com/",//"https://m.media-amazon.com/images/I/61z8UpgGr9L.jpg",
                    heardAt: Date.now,
                    sourceStationId: nil
                ))
            )
            .withPreviewEnv()
        }
    }
}
