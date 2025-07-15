import SwiftUI

struct SettingsScreen: View {
    
    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea()
            
            VStack {
                Text("Settings Screen")
            }
        }
        .navigationTitle("Settings")
    }
}
