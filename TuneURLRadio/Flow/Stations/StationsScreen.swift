import SwiftUI
import Kingfisher

struct StationsScreen: View {
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @Environment(StationsStore.self) var store
    @Environment(StateManager.self) var stateManager
    
    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea()
            
            ScrollView {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: 16),
                        count: horizontalSizeClass == .compact ? 2 : 4
                    ),
                    spacing: 16
                ) {
                    ForEach(store.stations) { station in
                        Button {
                            stateManager.switchStation(to: station)
                        } label: {
                            StationCard(station)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Stations")
    }
    
    @ViewBuilder
    private func StationCard(_ station: Station) -> some View {
        VStack {
            ZStack {
                Color.white
                VStack {
                    if let imageURL = station.imageURL {
                        KFImage(imageURL)
                            .resizable()
                            .scaledToFit()
                    } else {
                        Image("station-logo")
                            .resizable()
                            .scaledToFit()
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Color.black.opacity(0.1), radius: 8)
            
            Text(station.name)
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
    }
}

#Preview {
    NavigationStack {
        StationsScreen()
    }
    .withPreviewEnv()
}
