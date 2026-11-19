import SwiftUI
import Kingfisher

/// Listen tab: the stream / radio-nearby switcher, the stations, a sponsor and on-demand audio.
/// Replaces the old Stations tab.
struct ListenScreen: View {

    @Environment(StationsStore.self) private var store
    @Environment(StateManager.self) private var stateManager

    @State private var webPage: InAppWebPage?

    /// Two tiles across on iPhone, three to five on iPad.
    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 260), spacing: 10)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    SectionHeader(title: "How are you listening?")
                    Text("Stream KSAL here, or let the app hear a radio near you. Turls arrive either way.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ListeningModeSwitcher()

                SmallCapsHeader(title: "Pick a station")
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(store.stations) { station in
                        StationTile(station)
                    }
                }

                AdSlot(placement: .listen)

                SectionHeader(title: "On demand")
                    .padding(.top, 4)
                VStack(spacing: 0) {
                    ForEach(Array([KSAL.pastShows, KSAL.sportsAudio, KSAL.lineup].enumerated()), id: \.element.id) { index, link in
                        if index > 0 { Divider().padding(.leading, 64) }
                        Button {
                            webPage = InAppWebPage(url: link.url)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: link.systemImage)
                                    .font(.title3)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 40, height: 40)
                                Text(link.title)
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding()
            .padding(.bottom, 12)
            .readableWidth()
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Listen")
        .webPageSheet($webPage)
    }

    @ViewBuilder
    private func StationTile(_ station: Station) -> some View {
        let isCurrent = stateManager.currentStation?.id == station.id
        Button {
            stateManager.switchStation(to: station)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                StationLogo(station)
                    .frame(height: 72)
                    .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 1) {
                    Text(station.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text(isCurrent && stateManager.isPlaying ? "Playing" : station.shortDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(10)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isCurrent ? Color.accentColor : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(station.name)
        .accessibilityAddTraits(isCurrent ? .isSelected : [])
    }

    /// A station's logo on white, fitted (logos are wide, the KSAL 1150 art is square).
    @ViewBuilder
    private func StationLogo(_ station: Station) -> some View {
        ZStack {
            Color.white
            if let url = station.imageURL {
                KFImage(url)
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            } else {
                Image("station-logo")
                    .resizable()
                    .scaledToFit()
                    .padding(4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ListenScreen()
    }
    .withPreviewEnv()
}
