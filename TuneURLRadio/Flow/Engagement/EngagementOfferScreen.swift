import SwiftUI
import MessageUI
import SwiftData
import Kingfisher

private let log = Log(label: "EngagementOfferScreen")

struct EngagementOfferScreen: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(SettingsStore.self) private var settings
    @Environment(EngagementsStore.self) private var engagementsStore
    @Environment(GlobalSheetStore.self) private var sheetStore
    @Environment(VoiceCommandManager.self) private var voiceCommandsManager
    
    @State private var savedEngagement: SavedEngagement?
    @State private var autodismiss: Bool
    @State private var autoDismissTask: Task<Void, Never>? = nil
    
    private let engagement: Engagement
    
    init(engagement: Engagement, autodismiss: Bool) {
        self.engagement = engagement
        self.savedEngagement = nil
        self._autodismiss = State(wrappedValue: autodismiss)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            if engagement.type != .poll {
                Text("Are you interested?")
                    .font(.title.weight(.semibold))
            }
            
            VStack {
                if engagement.type != .poll {
                    if let description = engagement.description {
                        Text(description)
                            .font(.headline)
                            .lineLimit(0)
                    }
                }
                
                switch engagement.type {
                    case .openPage, .savePage:
                        PageEngagementView(engagement: engagement)
                        
                    case .coupon:
                        CouponEngagementView(engagement: engagement)
                        
                    case .poll:
                        PollEngagementView(
                            engagement: engagement,
                            resetAutodismiss: {
                                scheduleAutodismiss(after: 5)
                            }
                        )
                        
                    case .sms, .phone:
                        VStack {
                            Text("Phone Number")
                            Text(engagement.info ?? "")
                            Spacer()
                        }
                        .font(.headline)
                        .padding(.top, 16)
                        
                    case .api, .unknown:
                        FailedLoadContentView()
                }
            }
            
            switch engagement.type {
                case .openPage, .savePage, .coupon, .sms, .phone:
                    ActionButtons()
                    
                case .poll, .api, .unknown:
                    EmptyView()
            }
        }
        .fontDesign(.rounded)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .onAppear {
            if autodismiss {
                scheduleAutodismiss(after: autoDismissDelay)
            }
            if settings.voiceCommands {
                voiceCommandsManager.startRecognition()
            }
        }
        .onDisappear {
            if settings.voiceCommands {
                voiceCommandsManager.stopRecognition()
            }
        }
        .task {
            if settings.voiceCommands {
                for await recognition in voiceCommandsManager.recognitions {
                    handleRecognition(recognition)
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
    
    @ViewBuilder private func ActionButtons() -> some View {
        HStack {
            switch engagement.type {
                case .openPage, .savePage, .coupon:
                    EngagementActionButton("👍Yes, Save", color: Color.green) {
                        save()
                    }
                    
                case .sms:
                    EngagementActionButton("👍Yes, Write", color: Color.green) {
                        write()
                    }
                    
                case .phone:
                    EngagementActionButton("👍Yes, Call", color: Color.green) {
                        call()
                    }
                    
                case .poll, .api, .unknown:
                    // Should never happen
                    EngagementActionButton("👍Yes", color: Color.green) {
                        dismiss()
                    }
            }
            
            EngagementActionButton("👎No", color: Color.red) {
                dismiss()
            }
        }
    }
    
    // MARK: - Actions
    private func scheduleAutodismiss(after timeout: Double) {
        autoDismissTask?.cancel()
        autoDismissTask = Task {
            try? await Task.sleep(for: .seconds(timeout))
            guard !Task.isCancelled else { return }
            dismiss()
        }
    }
    
    private func handleRecognition(_ value: String) {
        if value.localizedCaseInsensitiveContains("yes") {
            switch engagement.type {
                case .openPage, .savePage, .coupon: save()
                case .sms: write()
                case .phone: call()
                case .poll, .api, .unknown: dismiss()
            }
        } else if value.localizedCaseInsensitiveContains("no") {
            dismiss()
        }
    }
    
    private func save() {
        ReportAction.interested(engagement).report()
        engagementsStore.saveForLater(engagement)
        dismiss()
    }
    
    private func call() {
        if let number = engagement.info,
           let callURL = URL(string: "tel://\(number)"),
           UIApplication.shared.canOpenURL(callURL) {
            ReportAction.interested(engagement).report()
            ReportAction.acted(engagement).report()
            UIApplication.shared.open(callURL)
        }
        dismiss()
    }
    
    private func write() {
        dismiss()
        if MFMessageComposeViewController.canSendText() {
            ReportAction.interested(engagement).report()
            ReportAction.acted(engagement).report()
            sheetStore.currentSMSComposer = engagement
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
            EngagementOfferScreen(
//                engagement: Engagement(
//                    id: 1,
//                    type: "open_page",
//                    name: "Concert Tickets",
//                    description: "Live Nations",
//                    info: "https://www.livenation.com/",//"https://m.media-amazon.com/images/I/61z8UpgGr9L.jpg",
//                    heardAt: Date.now,
//                    sourceStationId: nil
//                ),
                
//                engagement: Engagement(
//                    id: 1,
//                    type: "phone",
//                    name: "Call to studio",
//                    description: "Call Us and answer few questions",
//                    info: "+123456789012",
//                    heardAt: Date.now,
//                    sourceStationId: nil
//                ),

                engagement: Engagement(
                    id: 1,
                    type: "sms",
                    name: "Radio Lotery",
                    description: "Send sms to participate in lotery!",
                    info: "+123456789012",
                    heardAt: Date.now,
                    sourceStationId: nil
                ),
                
//                engagement: Engagement(
//                    id: 1,
//                    type: "poll",
//                    name: "Do you like this ad?",
//                    description: "Do you like this ad?",
//                    info: "+1",
//                    heardAt: Date.now,
//                    sourceStationId: nil
//                ),
                
                autodismiss: true
            )
            .withPreviewEnv()
        }
    }
}
