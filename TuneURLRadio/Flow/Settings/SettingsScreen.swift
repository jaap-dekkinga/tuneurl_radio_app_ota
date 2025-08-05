import SwiftUI

struct SettingsScreen: View {
    
    @Environment(UserSettings.self) private var settings
    @Environment(NotificationsStore.self) private var notificationsStore
    
    @State private var showPermissionsAlert = false
    
    var body: some View {
        @Bindable var settings = settings
        List {
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
            } header: {
                Text("General")
            }
            
            Section {
                NavigationLink(destination: ParsingSettingsScreen()) {
                    Label("Parsing Settings", systemImage: "slider.horizontal.3")
                }
            } header: {
                Text("Parsing")
            }
            
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
    
    private func checkNotificationsPermissions() {
        Task {
            let granted = await notificationsStore.checkNotificationsPermissions()
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
