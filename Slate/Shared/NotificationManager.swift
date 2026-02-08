import UserNotifications
import SwiftData
import WidgetKit

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    static let categoryID = "TODO_REMINDER"
    static let markDoneActionID = "MARK_DONE"

    private override init() {
        super.init()
    }

    func setup() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let markDone = UNNotificationAction(
            identifier: Self.markDoneActionID,
            title: "Mark Done",
            options: []
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryID,
            actions: [markDone],
            intentIdentifiers: []
        )

        center.setNotificationCategories([category])
    }

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { _, _ in }
    }

    func scheduleReminder(for todoID: String, title: String, after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Slate Reminder"
        content.body = title
        content.sound = .default
        content.categoryIdentifier = Self.categoryID
        content.userInfo = ["todoID": todoID]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(
            identifier: "todo-\(todoID)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for todoID: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["todo-\(todoID)"])
    }

    // MARK: - UNUserNotificationCenterDelegate

    // Handle action when user taps "Mark Done" from notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == Self.markDoneActionID {
            let userInfo = response.notification.request.content.userInfo
            if let todoID = userInfo["todoID"] as? String {
                markTodoDone(todoID: todoID)
            }
        }
        completionHandler()
    }

    // Show notification even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    private func markTodoDone(todoID: String) {
        let container = PersistenceConfig.modelContainer
        let context = ModelContext(container)
        guard let uuid = UUID(uuidString: todoID) else { return }

        do {
            let descriptor = FetchDescriptor<TodoItem>()
            let todos = try context.fetch(descriptor)
            if let todo = todos.first(where: { $0.id == uuid }) {
                todo.done = true
                todo.doneAt = .now
                try context.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            // silently fail
        }
    }
}
