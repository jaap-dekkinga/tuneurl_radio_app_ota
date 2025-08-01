import SwiftUI
import SwiftData

struct EngagementScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var savedEngagement: SavedEngagement?
    @State private var autoDismissTask: Task<Void, Never>? = nil
    
    private let engagement: Engagement
    private let stationId: Int?
    private let autodismiss: Bool
    
    init(savedEngagement: SavedEngagement) {
        self.engagement = savedEngagement.engagement
        self.savedEngagement = savedEngagement
        self.stationId = savedEngagement.sourceStationId
        self.autodismiss = false
    }
    
    init(engagement: Engagement, stationId: Int? = nil) {
        self.engagement = engagement
        self.savedEngagement = nil
        self.stationId = stationId
        self.autodismiss = true
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if let description = engagement.description {
                Text(description)
                    .font(.headline)
            } else {
                Text(engagementTitle)
                    .font(.headline)
            }
            
            if let info = engagement.info {
                switch engagement.type {
                    case .openWebPage, .saveWebPage, .coupon, .poll, .unknown:
                        if let websiteURL = URL(string: info, encodingInvalidCharacters: false) {
                            AppWebView(url: websiteURL)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        } else {
                            Text(info)
                        }
                        
                        if savedEngagement != nil {
                            ActionButton("Delete", .red) {
                                delete()
                            }
                        } else {
                            if engagement.type == .coupon {
                                ActionButton("Save Coupon") {
                                    save()
                                }
                            }
                            
                            if engagement.type == .openWebPage || engagement.type == .saveWebPage {
                                ActionButton("Save") {
                                    save()
                                }
                            }
                        }
                        
                    case .phone:
                        VStack(spacing: 32) {
                            Text("Call to: \(info)")
                            
                            ActionButton("Call Now!") {
                                UIApplication.shared.open(URL(string: "tel://\(info)")!)
                            }
                        }
                        
                    case .sms:
                        VStack(spacing: 32) {
                            Text("Send a message to: \(info)")
                            ActionButton("Message Now!") {
                                if let smsURL = URL(string: "sms:\(info)") {
                                    UIApplication.shared.open(smsURL)
                                }
                            }
                        }
                }
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .onAppear {
            if autodismiss {
                autoDismissTask = Task {
                    try? await Task.sleep(for: .seconds(autoDismissDelay))
                    dismiss()
                }
            }
        }
    }
    
    private var autoDismissDelay: Double {
        #if DEBUG
        return 5.0
        #else
        return 15.0
        #endif
    }
    
    private var engagementTitle: LocalizedStringKey {
        switch engagement.type {
            case .openWebPage, .saveWebPage: "Web Page"
            case .coupon: "Coupon"
            case .phone: "Phone Call"
            case .sms: "Message"
            case .poll: "Complete Survey"
            case .unknown: "Engagement"
        }
    }
    
    private func ActionButton(
        _ title: String,
        _ color: Color? = nil,
        _ action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
                .background(color ?? Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private func save() {
        let newEntity = SavedEngagement(
            engagement: engagement,
            stationId: stationId
        )
        context.insert(newEntity)
        do {
            try context.save()
        } catch {
            fatalError("Could not save engagement: \(error.localizedDescription)")
        }
        savedEngagement = newEntity
        
        if autodismiss {
            dismiss()
        }
    }
    
    private func delete() {
        guard let entity = savedEngagement else { return }
        context.delete(entity)
        do {
            try context.save()
        } catch {
            fatalError("Could not delete engagement: \(error.localizedDescription)")
        }
        savedEngagement = nil
    }
}

#Preview {
    @Previewable @State var show = false
    NavigationStack {
        Button("Show Engagement") {
            show.toggle()
        }
        .sheet(isPresented: $show) {
            EngagementScreen(engagement: Engagement(
                type: "open_page",
                name: "Concert Tickets",
                description: "Buy tickets to upcoming shows",
                info: "https://www.kissfm.ro/"
            ))
        }
    }
}
