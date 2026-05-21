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
    private let openedFromSavedList: Bool
    
    init(savedEngagement: SavedEngagement) {
        self.engagement = savedEngagement.engagement
        self.savedEngagement = savedEngagement
        self.openedFromSavedList = true
    }
    
    init(historyEngagement: HistoryEngagement) {
        self.engagement = historyEngagement.engagement
        self.savedEngagement = nil
        self.openedFromSavedList = false
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
                
                if let shareURL = engagement.handleURL {
                    ShareLink(item: shareURL) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background {
                                Capsule().fill(.primary.tertiary)
                            }
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        ReportAction.shared(engagement).report()
                    })
                }
            }
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .onAppear {
            // Report `acted` when the user opens a saved engagement to interact with it.
            // For history, the row tap in EngagementHistoryScreen already reports `acted`.
            if openedFromSavedList {
                ReportAction.acted(engagement).report()
            }
        }
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
