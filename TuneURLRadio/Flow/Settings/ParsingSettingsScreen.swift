import SwiftUI

struct ParsingSettingsScreen: View {
    
    @Environment(UserSettings.self) private var settings
    
    var body: some View {
        List {
            Section {
                VStack {
                    Text("OTA Match Threshold: **\(settings.otaMatchThreshold)%**")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Slider(value: .init(get: {
                        Double(settings.otaMatchThreshold)
                    }, set: { newValue in
                        settings.$otaMatchThreshold.withLock {
                            $0 = Int(newValue)
                        }
                    }), in: 0...90) {
                        Text("OTA Match Threshold")
                    } minimumValueLabel: {
                        Text("0%")
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("90%")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section {
                VStack {
                    Text("Stream Match Threshold: **\(settings.streamMatchThreshold)%**")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Slider(value: .init(get: {
                        Double(settings.streamMatchThreshold)
                    }, set: { newValue in
                        settings.$streamMatchThreshold.withLock {
                            $0 = Int(newValue)
                        }
                    }), in: 0...90) {
                        Text("Stream Match Threshold")
                    } minimumValueLabel: {
                        Text("0%")
                            .foregroundStyle(.secondary)
                    } maximumValueLabel: {
                        Text("90%")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Parsing Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ParsingSettingsScreen()
            .withPreviewEnv()
    }
}
