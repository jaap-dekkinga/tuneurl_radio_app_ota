import SwiftUI
import Kingfisher

/// Listen tab: now playing (with Turl listening), the stations, and past shows.
/// Replaces the old Stations tab.
struct ListenScreen: View {

    @Environment(StationsStore.self) private var store
    @Environment(StateManager.self) private var stateManager

    @State private var webPage: InAppWebPage?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                NowPlayingCard()

                SmallCapsHeader(title: "Stations")
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(store.stations) { station in
                        StationTile(station)
                    }
                }

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
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Listen")
        .webPageSheet($webPage)
    }

    @ViewBuilder
    private func NowPlayingCard() -> some View {
        let station = stateManager.currentStation
        VStack(alignment: .leading, spacing: 14) {
            Button {
                if station != nil { stateManager.expandPlayer() }
            } label: {
                HStack(spacing: 14) {
                    StationArtwork(station, size: 72)
                    VStack(alignment: .leading, spacing: 2) {
                        if stateManager.isPlaying {
                            Text("● LIVE")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color(red: 1, green: 0.42, blue: 0.42))
                        }
                        Text(station?.name ?? "Choose a station")
                            .font(.headline)
                            .foregroundStyle(.white)
                        if let station {
                            Text(station.shortDescription)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(station != nil ? "Opens the full player" : "")

            HStack(spacing: 12) {
                Button {
                    stateManager.switchPlaybackState()
                } label: {
                    Image(systemName: stateManager.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(.white, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(station == nil)
                .accessibilityLabel(stateManager.isPlaying ? "Stop" : "Play")

                Button {
                    stateManager.switchListening()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: stateManager.isListening ? "waveform.badge.magnifyingglass" : "speaker.zzz.fill")
                            .symbolEffect(.pulse, isActive: stateManager.isListening)
                        Text(stateManager.isListening ? "Listening for Turls" : "Turl listening off")
                            .font(.subheadline.weight(.medium))
                        Spacer(minLength: 0)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(white: 0.11), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private func StationTile(_ station: Station) -> some View {
        let isCurrent = stateManager.currentStation?.id == station.id
        Button {
            stateManager.switchStation(to: station)
        } label: {
            HStack(spacing: 10) {
                StationArtwork(station, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(station.name)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(isCurrent && stateManager.isPlaying ? "Playing" : station.shortDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(10)
            .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
            .background(Color(uiColor: .secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func StationArtwork(_ station: Station?, size: CGFloat) -> some View {
        ZStack {
            Color.white
            if let url = station?.imageURL {
                KFImage(url)
                    .resizable()
                    .scaledToFit()
            } else {
                Image("station-logo")
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        ListenScreen()
    }
    .withPreviewEnv()
}
