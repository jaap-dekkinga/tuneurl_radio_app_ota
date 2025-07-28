import SwiftUI

struct SettingsScreen: View {
    
    var body: some View {
        List {
            Section {
                NavigationLink(destination: ParsingSettingsScreen()) {
                    Label("Parsing Settings", systemImage: "slider.horizontal.3")
                }
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
            } footer: {
                versionFooter
            }
        }
        .background(Color(uiColor: .secondarySystemBackground).ignoresSafeArea())
        .navigationTitle("Settings")
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
    }
}
