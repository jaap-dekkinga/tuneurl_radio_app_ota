import SwiftUI
import SwiftData
import Kingfisher
import LinkPresentation

private let log = Log(label: "ViewEngagementScreen")

struct ViewEngagementScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(EngagementsStore.self) private var engagementsStore
    
    @State private var savedEngagement: SavedEngagement?
    @State private var presentedWebURL: URL?
    @State private var presentedCouponURL: URL?
    @State private var linkMetadata: LPLinkMetadata?
    
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
            
            // Content preview
            switch engagement.type {
                case .openPage, .savePage:
                    PagePreview()
                    
                case .coupon:
                    CouponPreview()
                    
                case .phone:
                    PhonePreview()
                    
                case .sms:
                    PhonePreview()
                    
                case .poll, .api, .unknown:
                    Text("Failder to load content.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
            }
            
            // Primary action button
            PrimaryActionButton()
            
            // Secondary actions: Save/Delete, Share
            SecondaryActions()
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .sheet(item: $presentedWebURL) { url in
            SafariView(url: url)
                .ignoresSafeArea()
        }
        .sheet(item: $presentedCouponURL) { url in
            CouponFullScreenView(url: url) {
                presentedCouponURL = nil
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder private func PagePreview() -> some View {
        if let handleURL = engagement.handleURL {
            URLPreview(previewURL: handleURL, linkMetadata: $linkMetadata)
                .frame(maxHeight: 220)
                .padding(.vertical, 8)
        } else {
            FailedLoadContentView()
        }
    }
    
    @ViewBuilder private func CouponPreview() -> some View {
        if let handleURL = engagement.handleURL {
            KFImage(handleURL)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onTapGesture {
                    openCoupon()
                }
            Spacer(minLength: 0)
        } else {
            FailedLoadContentView()
        }
    }
    
    @ViewBuilder private func PhonePreview() -> some View {
        VStack {
            Text("Phone Number")
                .font(.headline)
            Text(engagement.info ?? "")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
    }
    
    @ViewBuilder private func PrimaryActionButton() -> some View {
        switch engagement.type {
            case .openPage, .savePage:
                EngagementActionButton("Open Website", color: Color.blue) {
                    openWebsite()
                }
                
            case .coupon:
                EngagementActionButton("View Coupon", color: Color.blue) {
                    openCoupon()
                }
                
            case .phone:
                EngagementActionButton("Call", color: Color.blue) {
                    placeCall()
                }
                
            case .sms:
                EngagementActionButton("Send Message", color: Color.blue) {
                    // SMS composing is on EngagementOfferScreen via GlobalSheetStore.
                    // For a saved SMS engagement, we open the phone dialer's
                    // message composer via tel: alternative is not available;
                    // open the system Messages app with the number prefilled.
                    sendMessage()
                }
                
            case .poll, .api, .unknown:
                EmptyView()
        }
    }
    
    @ViewBuilder private func SecondaryActions() -> some View {
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
    
    // MARK: - Actions
    
    private func openWebsite() {
        guard let url = engagement.handleURL else { return }
        ReportAction.acted(engagement).report()
        presentedWebURL = url
    }
    
    private func openCoupon() {
        guard let url = engagement.handleURL else { return }
        ReportAction.acted(engagement).report()
        presentedCouponURL = url
    }
    
    private func placeCall() {
        guard
            let number = engagement.info,
            let callURL = URL(string: "tel://\(number)"),
            UIApplication.shared.canOpenURL(callURL)
        else { return }
        ReportAction.acted(engagement).report()
        UIApplication.shared.open(callURL)
    }
    
    private func sendMessage() {
        guard
            let number = engagement.info,
            let smsURL = URL(string: "sms:\(number)"),
            UIApplication.shared.canOpenURL(smsURL)
        else { return }
        ReportAction.acted(engagement).report()
        UIApplication.shared.open(smsURL)
    }

    private func save() {
        savedEngagement = engagementsStore.saveForLater(engagement)
    }

    private func delete() {
        guard let entity = savedEngagement else { return }
        engagementsStore.delete(entity)
        savedEngagement = nil
        dismiss()
    }
}

// MARK: - URL extension for sheet(item:)

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

// MARK: - Coupon full-screen view

private struct CouponFullScreenView: View {
    let url: URL
    let onDone: () -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                KFImage(url)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        onDone()
                    }
                    .foregroundStyle(.white)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
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
                    info: "https://www.livenation.com/",
                    heardAt: Date.now,
                    sourceStationId: nil
                ))
            )
            .withPreviewEnv()
        }
    }
}
