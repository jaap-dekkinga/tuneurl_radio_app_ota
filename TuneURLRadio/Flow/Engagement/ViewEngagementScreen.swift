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
    @State private var showDeleteConfirmation = false
    
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
                    
                case .phone, .sms:
                    PhonePreview()
                    
                case .poll, .api, .unknown:
                    Text("Failed to load content.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(maxHeight: .infinity)
            }
            
            // Primary action button
            PrimaryActionButton()
            
            // Secondary actions: Share, Save/Delete
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
    
    // MARK: - Content previews
    
    @ViewBuilder private func PagePreview() -> some View {
        if let handleURL = engagement.handleURL {
            Button {
                openWebsite()
            } label: {
                URLPreview(previewURL: handleURL, linkMetadata: $linkMetadata)
                    .frame(maxHeight: 220)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        } else {
            FailedLoadContentView()
        }
    }
    
    @ViewBuilder private func CouponPreview() -> some View {
        if let handleURL = engagement.handleURL {
            Button {
                openCoupon()
            } label: {
                KFImage(handleURL)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        } else {
            FailedLoadContentView()
        }
    }
    
    @ViewBuilder private func PhonePreview() -> some View {
        VStack(spacing: 8) {
            Text("Phone Number")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if let number = engagement.info {
                Button {
                    switch engagement.type {
                        case .phone: placeCall()
                        case .sms: sendMessage()
                        default: break
                    }
                } label: {
                    Text(number)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.tint)
                        .underline()
                }
                .buttonStyle(.plain)
            }
            
            Spacer(minLength: 0)
        }
        .padding(.top, 16)
    }
    
    // MARK: - Action buttons
    
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
                    sendMessage()
                }
                
            case .poll, .api, .unknown:
                EmptyView()
        }
    }
    
    @ViewBuilder private func SecondaryActions() -> some View {
        HStack(spacing: 12) {
            if let shareURL = engagement.handleURL {
                ShareLink(item: shareURL) {
                    Text("Share")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.gradient)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    ReportAction.shared(engagement).report()
                })
            }
            
            if savedEngagement == nil {
                EngagementActionButton(saveButtonTitle, color: Color.green) {
                    save()
                }
            } else {
                EngagementActionButton(deleteButtonTitle, color: Color.red) {
                    showDeleteConfirmation = true
                }
            }
        }
        .confirmationDialog(
            "Delete this saved item?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                delete()
            }
            Button("Cancel", role: .cancel) {}
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
        UIApplication.shared.open(url)
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
