import SwiftUI

struct SettingsScreen: View {
    
    @Environment(SettingsStore.self) private var settings
    @Environment(NotificationsManager.self) private var notifications
    
    @State private var showPermissionsAlert = false
    
    var body: some View {
        List {
            GeneralSection()
            ParsingSection()
            InfoSection()
        }
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("Settings")
        .alert("Enable Notifications", isPresented: $showPermissionsAlert, actions: {
            Button("Cancel", role: .cancel) {}
            Button("Open Settings") {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
        }, message: {
            Text("This feature requires notifications permission. Please enable notifications in Settings.")
        })
        .onChange(of: settings.engagementDisplayMode) { oldValue, newValue in
            if newValue == .notification {
                checkNotificationsPermissions()
            }
        }
    }
    
    @ViewBuilder private func GeneralSection() -> some View {
        @Bindable var settings = settings
        Section {
            Picker(
                "Show \"Turls\" as",
                systemImage: "rectangle.stack",
                selection: $settings.engagementDisplayMode
            ) {
                ForEach(EngagementDisplayMode.allCases, id: \.self) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            
            Toggle(
                "Store \"Turls\" history",
                systemImage: "calendar.day.timeline.left",
                isOn: $settings.storeAllEngagementsHistory
            )
            
            Toggle(
                "Voice Commands",
                systemImage: "waveform",
                isOn: $settings.voiceCommands
            )
        } header: {
            Text("General")
        }
    }
    
    @ViewBuilder private func ParsingSection() -> some View {
        Section {
            NavigationLink(destination: ParsingSettingsScreen()) {
                Label("Parsing Settings", systemImage: "slider.horizontal.3")
            }
        } header: {
            Text("Parsing")
        }
    }
    
    @ViewBuilder private func InfoSection() -> some View {
        Section {
            Button {
                UIApplication.shared.open(Constants.websiteURL)
            } label: {
                HStack {
                    Label {
                        Text("Website")
                    } icon: {
                        Image(systemName: "globe")
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Button {
                UIApplication.shared.open(Constants.privacyPolicyURL)
            } label: {
                HStack {
                    Label {
                        Text("Privacy Policy")
                    } icon: {
                        Image(systemName: "shield")
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Info")
        } footer: {
            versionFooter
        }
    }
    
    private func checkNotificationsPermissions() {
        Task {
            let granted = await notifications.checkNotificationsPermissions()
            if !granted {
                showPermissionsAlert.toggle()
                settings.$engagementDisplayMode.withLock {
                    $0 = .modal
                }
            }
        }
    }
    
    private var versionFooter: some View {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "–"
        
        return Text("Version \(version)(\(build))")
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
            .withPreviewEnv()
    }
}
