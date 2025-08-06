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
        List {
            ForEach(items) { item in
                Section {
                    Button {
                        selected = item
                    } label: {
                        EngagementCard(
                            infoURL: item.engagementURL,
                            info: item.engagementDescription,
                            stationId: item.sourceStationId,
                            date: item.saveDate
                        )
                    }
                    .buttonStyle(.plain)
                    .swipeActions(content: {
                        Button(role: .destructive) {
                            withAnimation {
                                engagementsStore.delete(item)
                            }
                        } label: {
                            Text("Delete")
                        }
                    })
                }
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
        }
        .listSectionSpacing(16)
        .overlay {
            if items.isEmpty {
                ContentUnavailableView(
                    "Looks like you don't have any Turls yet.",
                    systemImage: "tray",
                    description: Text("Start listen radio and Turls will appear here.")
                )
            }
        }
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
