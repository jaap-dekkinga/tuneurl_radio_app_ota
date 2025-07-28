import Pulse

struct Log {
    private let label: String
    
    init(label: String) {
        self.label = label
    }
    
    func write(
        _ message: String,
        level: LoggerStore.Level = .info
    ) {
#if DEBUG
        print(message)
#endif
        LoggerStore.shared.storeMessage(
            label: label,
            level: level,
            message: message
        )
    }
}
