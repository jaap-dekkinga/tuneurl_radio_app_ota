import SwiftUI

/// Turls tab: saved Turls and the history of heard Turls, behind one switch.
struct TurlsScreen: View {

    enum Mode: String, CaseIterable, Identifiable {
        case saved = "Saved"
        case heard = "Heard"
        var id: Self { self }
    }

    @State private var mode: Mode = .saved

    var body: some View {
        Group {
            switch mode {
            case .saved:
                SavedEngagementsScreen()
            case .heard:
                EngagementHistoryScreen()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            Picker("Show", selection: $mode) {
                ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
        }
    }
}
