import SwiftUI
import Kingfisher

/// Two ways to get Turls, shown as one sliding control.
///
/// - Stream mode (the app plays the station): the panel sits on the right and shows the
///   station. The uncovered button on the left switches to radio mode.
/// - Radio mode (the app listens through the microphone to a radio nearby): the panel slides
///   left and shows the listening state. The uncovered button on the right starts the stream.
///
/// StateManager already keeps the two exclusive: `play()` stops the microphone, `stop()` starts it.
/// Tap the uncovered button or swipe the panel to switch.
struct ListeningModeSwitcher: View {

    @Environment(StateManager.self) private var stateManager
    @Environment(StationsStore.self) private var stationsStore

    enum Mode { case stream, radio }

    @GestureState private var dragOffset: CGFloat = 0

    private let edgeWidth: CGFloat = 80
    private let gap: CGFloat = 6
    private let height: CGFloat = 176

    private var mode: Mode {
        stateManager.isPlaying ? .stream : .radio
    }

    var body: some View {
        GeometryReader { proxy in
            let panelWidth = max(proxy.size.width - edgeWidth - gap, 0)
            let travel = edgeWidth + gap
            let base: CGFloat = mode == .stream ? travel : 0
            let x = min(max(base + dragOffset, 0), travel)

            ZStack(alignment: .topLeading) {
                HStack(spacing: 0) {
                    EdgeButton(
                        systemImage: "waveform.badge.magnifyingglass",
                        title: "Radio\nnearby",
                        accessibilityLabel: "Switch to listening for Turls from a radio nearby",
                        action: switchToRadio
                    )
                    .accessibilityHidden(mode == .radio)

                    Spacer(minLength: 0)

                    EdgeButton(
                        systemImage: "play.fill",
                        title: "Stream\nin app",
                        accessibilityLabel: "Switch to streaming the station in the app",
                        action: switchToStream
                    )
                    .accessibilityHidden(mode == .stream)
                }

                Group {
                    switch mode {
                    case .stream: StreamPanel()
                    case .radio: RadioPanel()
                    }
                }
                .frame(width: panelWidth, height: height)
                .background(Color(white: 0.11), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
                .offset(x: x)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation.width
                        }
                        .onEnded { value in
                            if value.translation.width < -40, mode == .stream {
                                switchToRadio()
                            } else if value.translation.width > 40, mode == .radio {
                                switchToStream()
                            }
                        }
                )
            }
        }
        .frame(height: height)
        .padding(4)
        .background(Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .animation(.spring(response: 0.42, dampingFraction: 0.86), value: mode)
        .animation(.interactiveSpring(), value: dragOffset)
        .sensoryFeedback(.selection, trigger: mode)
    }

    // MARK: - Actions

    private func switchToRadio() {
        if stateManager.isPlaying {
            stateManager.stop()              // also starts the microphone
        } else {
            stateManager.startListening()
        }
    }

    private func switchToStream() {
        if stateManager.currentStation != nil {
            stateManager.play()              // also stops the microphone
        } else if let station = stationsStore.stations.first(where: { $0.id == KSAL.newsStationID })
                    ?? stationsStore.stations.first {
            stateManager.switchStation(to: station)
        }
    }

    // MARK: - Panels

    @ViewBuilder
    private func StreamPanel() -> some View {
        let station = stateManager.currentStation
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Color.white
                    if let url = station?.imageURL {
                        KFImage(url).resizable().scaledToFit()
                    } else {
                        Image("station-logo").resizable().scaledToFit()
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Label("Streaming live", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color(red: 1, green: 0.45, blue: 0.45))
                    Text(station?.name ?? "")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            Text("Turls pop up here while you listen.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                stateManager.expandPlayer()
            } label: {
                Label("Open player", systemImage: "chevron.up")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 36)
                    .background(Color.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func RadioPanel() -> some View {
        let listening = stateManager.isListening
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: listening ? "waveform.badge.magnifyingglass" : "speaker.zzz.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .symbolEffect(.pulse, isActive: listening)
                    .foregroundStyle(listening ? Color.accentColor : .white.opacity(0.6))
                    .frame(width: 60, height: 60)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(listening ? "Listening for Turls" : "Listening paused")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(listening ? Color(red: 1, green: 0.45, blue: 0.45) : .white.opacity(0.6))
                    Text("Radio nearby")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }

            Text("Play KSAL on any radio near you. Your phone hears the Turls through the microphone.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button {
                if listening { stateManager.stopListening() } else { stateManager.startListening() }
            } label: {
                Label(listening ? "Pause listening" : "Resume listening",
                      systemImage: listening ? "pause.fill" : "mic.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 36)
                    .background(Color.white.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// The uncovered button at either end of the switcher.
private struct EdgeButton: View {
    let systemImage: String
    let title: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 52, height: 52)
                    .background(Color(uiColor: .tertiarySystemGroupedBackground), in: Circle())
                Text(title)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(width: 80)
        .accessibilityLabel(accessibilityLabel)
    }
}
