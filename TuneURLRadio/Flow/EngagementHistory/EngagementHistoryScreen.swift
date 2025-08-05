import SwiftUI
import SwiftData

struct EngagementHistoryScreen: View {
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.modelContext) private var context
    @Environment(EngagementsStore.self) private var engagementsStore
    
    @Query(sort: \HistoryEngagement.saveDate, order: .reverse)
    private var items: [HistoryEngagement]
    
    @State private var selected: HistoryEngagement?
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: 12),
                    count: horizontalSizeClass == .compact ? 1 : 2
                ),
                spacing: 12
            ) {
                ForEach(items) { item in
                    Button {
                        selected = item
                    } label: {
                        EngagementHistoryCard(
                            infoURL: item.engagementURL,
                            info: item.engagementDescription,
                            stationId: item.sourceStationId,
                            date: item.saveDate
                        )
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            engagementsStore.delete(item)
                        } label: {
                            Text("Delete")
                        }
                    }
                }
            }
            .padding()
        }
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "Looks like you don't have any Turls yet.",
                    systemImage: "tray",
                    description: Text("Start listen radio and Turls will appear here.")
                )
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .navigationTitle("Turls")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Clear") {
                    engagementsStore.clearHistory()
                }
            }
        }
        .sheet(item: $selected) { item in
            EngagementScreen(historyEngagement: item)
                .withEnv()
        }
    }
}

#Preview {
    EngagementHistoryScreen()
        .withPreviewEnv()
}
