import SwiftUI
import Kingfisher

/// The two ways to get Turls, as one switch plus one status row.
///
/// - Stream in app: the app plays the station and catches Turls in the stream.
/// - Listen along: the app listens through the microphone to a radio nearby.
///
/// StateManager already keeps the two modes exclusive: `play()` stops the microphone and
/// `stop()` starts it. So stopping the stream also switches to Listen along.
struct ListeningModeSwitcher: View {

    @Environment(StateManager.self) private var stateManager
    @Environment(StationsStore.self) private var stationsStore

    @Namespace private var thumb

    /// Pill colour for Listen along while the microphone is off. White text on it passes 4.5:1.
    private static let pausedGrey = Color(white: 0.32)

    enum Mode { case stream, listenAlong }

    private var mode: Mode {
        stateManager.isPlaying ? .stream : .listenAlong
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 0) {
                Segment(.stream, title: "Stream in app", systemImage: "play.fill",
                        pill: Color.accentColor)
                // Red with the magnifying glass while the microphone listens.
                // Dark grey with the sleeping speaker while it does not.
                Segment(.listenAlong, title: "Listen along",
                        systemImage: stateManager.isListening ? "waveform.badge.magnifyingglass" : "speaker.zzz.fill",
                        pill: stateManager.isListening ? Color.accentColor : Self.pausedGrey)
            }
            .padding(4)
            .background(Color(uiColor: .tertiarySystemFill), in: Capsule())
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Listening mode")

            switch mode {
            case .stream: StreamStatus()
            case .listenAlong: ListenAlongStatus()
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.snappy(duration: 0.3), value: mode)
        .animation(.snappy(duration: 0.3), value: stateManager.isListening)
        .sensoryFeedback(.selection, trigger: mode)
    }

    // MARK: - Switch

    @ViewBuilder
    private func Segment(_ target: Mode, title: String, systemImage: String, pill: Color) -> some View {
        let isActive = mode == target
        Button {
            select(target)
        } label: {
            HStack(spacing: 8) {
                    Image(systemName: systemImage)
                    .imageScale(.medium)
                    .contentTransition(.symbolEffect(.replace))
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(isActive ? Color.white : Color.primary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                if isActive {
                    Capsule()
                        .fill(pill)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                        .matchedGeometryEffect(id: "thumb", in: thumb)
                }
            }
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
        .accessibilityHint(target == .listenAlong && isActive
                           ? (stateManager.isListening ? "Double-tap to pause listening" : "Double-tap to start listening")
                           : "")
    }

    private func select(_ target: Mode) {
        // Listen along is a toggle: tapping it while it is red pauses the microphone
        // (dark grey, sleeping speaker), tapping it again starts listening.
        if target == .listenAlong, mode == .listenAlong {
            if stateManager.isListening {
                stateManager.stopListening()
            } else {
                stateManager.startListening()
            }
            return
        }
        guard target != mode else { return }
        switch target {
        case .stream:
            if stateManager.currentStation != nil {
                stateManager.play()              // also stops the microphone
            } else if let station = stationsStore.stations.first(where: { $0.id == KSAL.newsStationID })
                        ?? stationsStore.stations.first {
                stateManager.switchStation(to: station)
            }
        case .listenAlong:
            stateManager.stop()                  // also starts the microphone
        }
    }

    // MARK: - Status rows

    @ViewBuilder
    private func StreamStatus() -> some View {
        let station = stateManager.currentStation
        HStack(spacing: 12) {
            Button {
                stateManager.expandPlayer()
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Color.white
                        if let url = station?.imageURL {
                            KFImage(url).resizable().scaledToFit()
                        } else {
                            Image("station-logo").resizable().scaledToFit()
                        }
                    }
                    .frame(width: 48, height: 48)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(station?.name ?? "")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Circle()
                                .fill(Color.accentColor)
                                .frame(width: 7, height: 7)
                            Text("Live · catching Turls")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the full player")

            RoundButton(systemImage: "stop.fill", label: "Stop the stream") {
                stateManager.stop()
            }
        }
        .padding(.horizontal, 4)
    }

    @ViewBuilder
    private func ListenAlongStatus() -> some View {
        let listening = stateManager.isListening
        HStack(spacing: 12) {
            Image(systemName: listening ? "waveform.badge.magnifyingglass" : "speaker.zzz.fill")
                .font(.system(size: 24, weight: .semibold))
                .symbolEffect(.pulse, isActive: listening)
                .foregroundStyle(listening ? Color.accentColor : Color.secondary)
                .frame(width: 48, height: 48)
                .contentTransition(.symbolEffect(.replace))
                .background((listening ? Color.accentColor : Color.secondary).opacity(0.12),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(listening ? "Listening for Turls" : "Listening paused")
                    .font(.headline)
                Text("Keep your phone near the radio")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)

            RoundButton(systemImage: listening ? "pause.fill" : "mic.fill",
                        label: listening ? "Pause listening" : "Resume listening") {
                if listening { stateManager.stopListening() } else { stateManager.startListening() }
            }
        }
        .padding(.horizontal, 4)
    }

    private func RoundButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .tertiarySystemFill), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
