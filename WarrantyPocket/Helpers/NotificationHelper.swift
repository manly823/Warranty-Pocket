import UserNotifications

final class NotificationHelper {
    static let shared = NotificationHelper()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleAll(for warranties: [WarrantyItem]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        for item in warranties where !item.isArchived && item.status != .expired {
            scheduleReminder(for: item, daysBefore: 30, label: "in 30 days")
            scheduleReminder(for: item, daysBefore: 7, label: "in 7 days")
            scheduleReminder(for: item, daysBefore: 1, label: "tomorrow")
        }
    }

    private func scheduleReminder(for item: WarrantyItem, daysBefore: Int, label: String) {
        guard let fireDate = Calendar.current.date(byAdding: .day, value: -daysBefore, to: item.expiryDate),
              fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "⚠️ Warranty Expiring"
        content.body = "\(item.name) warranty expires \(label). Check your coverage at \(item.store)."
        content.sound = .default

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        comps.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let req = UNNotificationRequest(identifier: "wp_\(item.id.uuidString)_\(daysBefore)",
                                        content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }
}
