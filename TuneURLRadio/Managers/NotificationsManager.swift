import Foundation
import UserNotifications
import TuneURL

private let log = Log(label: "NotificationsManager")

@MainActor @Observable
class NotificationsManager: NSObject {
    
    static let shared = NotificationsManager()
    
    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func checkNotificationsPermissions() async -> Bool {
        let notificationSettings = await UNUserNotificationCenter.current().notificationSettings()
        switch notificationSettings.authorizationStatus {
            case .notDetermined, .provisional:
                do {
                    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                    return await checkNotificationsPermissions()
                } catch {
                    log.write("Failed to request notification permissions: \(error)")
                    return false
                }
                
            case .authorized, .ephemeral:
                return true
                
            case .denied:
                return false
                
            @unknown default:
                return false
        }
    }
    
    func showNotification(for engagement: Engagement) {
        Task {
            guard let matchData = try? JSONEncoder().encode(engagement) else { return }
            let content = UNMutableNotificationContent()
            content.sound = .default
            content.title = "New Turl!"
            content.body = engagement.description?.trimmed.nilIfEmpty ?? "If you're interested, then click 'save'"
            content.interruptionLevel = .timeSensitive
            content.relevanceScore = 1.0
            content.userInfo = [
                "data": matchData
            ]
                
            let request = UNNotificationRequest(
                identifier: engagement.id.description,
                content: content,
                trigger: nil
            )
            
            let notificationCenter = UNUserNotificationCenter.current()
            do {
                try await notificationCenter.add(request)
            } catch {
                log.write(
                    "Failed to add notification request: \(error.localizedDescription)",
                    level: .error
                )
            }
        }
    }
}

extension NotificationsManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        return [.banner, .list]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard
            let data = response.notification.request.content.userInfo["data"] as? Data,
            let engagement = try? JSONDecoder().decode(Engagement.self, from: data)
        else { return }
        StateManager.shared.presentEngagement(
            engagement: engagement,
            autodismiss: false,
            forceCloseCurrent: true
        )
    }
}
