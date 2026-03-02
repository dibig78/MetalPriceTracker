import Foundation
import UserNotifications

// MARK: - 알림 서비스
final class NotificationService {

    static let shared = NotificationService()

    private init() {}

    // 디바이스 토큰 (UserDefaults에 저장)
    var deviceToken: String {
        get { UserDefaults.standard.string(forKey: "device_token") ?? UUID().uuidString }
        set { UserDefaults.standard.set(newValue, forKey: "device_token") }
    }

    // MARK: - 알림 권한 요청

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            return granted
        } catch {
            print("Notification permission error: \(error)")
            return false
        }
    }

    // MARK: - 로컬 알림 발송

    func scheduleLocalNotification(metalName: String, price: Double, direction: String) {
        let content = UNMutableNotificationContent()
        content.title = "시세 알림"
        content.body = "\(metalName) 가격이 $\(String(format: "%.2f", price)) \(direction == "above" ? "이상" : "이하")에 도달했습니다."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }

    // MARK: - 알림 권한 상태 확인

    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
}
