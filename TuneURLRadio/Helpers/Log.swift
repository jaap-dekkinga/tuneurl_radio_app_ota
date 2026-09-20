import Pulse
import Foundation

struct Log {
    private let label: String

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    init(label: String) {
        self.label = label
    }

    func write(
        _ message: String,
        level: LoggerStore.Level = .info
    ) {
        let timestamp = Log.timestampFormatter.string(from: Date())
        let stamped = "[\(timestamp)] \(message)"

#if DEBUG
        print(stamped)
#endif
        LoggerStore.shared.storeMessage(
            label: label,
            level: level,
            message: stamped
        )
    }
}
