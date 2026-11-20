import SwiftUI

/// Gear button in the top-right of the navigation bar that opens Settings as a sheet.
/// Used on Home and Turls.
private struct SettingsButtonModifier: ViewModifier {

    @State private var showSettings = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack {
                    SettingsScreen()
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") { showSettings = false }
                            }
                        }
                }
                .withEnv()
            }
    }
}

extension View {
    /// Adds the Settings gear to this screen's navigation bar.
    func settingsButton() -> some View {
        modifier(SettingsButtonModifier())
    }
}
