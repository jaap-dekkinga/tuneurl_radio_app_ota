import SwiftUI

struct SleepTimerButton: View {
    
    @Environment(StateManager.self) private var stateManager
    @State private var startDate = Date.now
    
    var body: some View {
        Menu {
            Button("2 hour", action: { stateManager.setSleepTimer(for: 2 * 60 * 60) })
            Button("1 hour", action: { stateManager.setSleepTimer(for: 60 * 60) })
            Button("30 mins", action: { stateManager.setSleepTimer(for: 30 * 60) })
            Button("15 mins", action: { stateManager.setSleepTimer(for: 15 * 60) })
            #if DEBUG
            Button("1 min", action: { stateManager.setSleepTimer(for: 60) })
            #endif
            Button("None", action: { stateManager.setSleepTimer(for: nil) })
        } label: {
            let sleepDate = stateManager.nextSleepDate()
            Label("Sleep", systemImage: "stopwatch")
                .symbolVariant(sleepDate != nil ? .fill : .none)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    Capsule()
                        .fill(.primary.tertiary)
                }
                .overlay(alignment: .bottom) {
                    if let sleepDate {
                        GeometryReader { proxy in
                            TimelineView(.periodic(from: startDate, by: 5)) { context in
                                Text("Sleep in: ") + Text(formattedTimer(sleepDate))
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .offset(y: proxy.size.height + 2)
                        }
                    }
                }
        }
    }
    
    private func formattedTimer(_ date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: interval) ?? ">1m"
    }
}
