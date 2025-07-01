import Foundation
import UserNotifications

import PreReleaseNotificationClient
import PreReleaseNotificationModel
import BookModel

public extension PreReleaseNotificationClient {
    static func generate() -> PreReleaseNotificationClient {
        let storage = PreReleaseNotificationStorage()

        return .init(
            fetchAll: {
                await storage.fetchAll()
            },
            fetch: { bookId in
                await storage.fetch(for: bookId)
            },
            add: { notification in
                await storage.add(notification)
                await scheduleLocalNotification(for: notification)
            },
            remove: { bookId in
                if let notification = await storage.fetch(for: bookId) {
                    await cancelLocalNotification(identifier: notification.notificationIdentifier)
                }
                await storage.remove(for: bookId)
            },
            update: { notification in
                await storage.update(notification)
                await cancelLocalNotification(identifier: notification.notificationIdentifier)
                if notification.isValidForScheduling {
                    await scheduleLocalNotification(for: notification)
                }
            },
            scheduleNotification: { notification in
                await scheduleLocalNotification(for: notification)
            },
            cancelNotification: { identifier in
                await cancelLocalNotification(identifier: identifier)
            },
            removeExpiredNotifications: {
                await storage.removeExpiredNotifications()
            }
        )
    }
}

private func scheduleLocalNotification(for notification: PreReleaseNotification) async {
    guard notification.isValidForScheduling else { return }

    let content = UNMutableNotificationContent()
    content.title = "📚 新刊発売のお知らせ"
    content.body = "\(notification.bookTitle) の発売日が近づいています"
    content.sound = .default
    content.userInfo = [
        "type": "pre_release",
        "bookId": notification.bookId.rawValue.uuidString,
        "bookTitle": notification.bookTitle,
    ]

    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: notification.notificationDate)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(
        identifier: notification.notificationIdentifier,
        content: content,
        trigger: trigger
    )

    do {
        try await UNUserNotificationCenter.current().add(request)
    } catch {
        print("Failed to schedule notification: \(error)")
    }
}

private func cancelLocalNotification(identifier: String) async {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
}

extension UserDefaults: @unchecked @retroactive Sendable {}

private actor PreReleaseNotificationStorage: Sendable {
    private var notifications: [PreReleaseNotification] = []
    private let userDefaults = UserDefaults.standard
    private let storageKey = "pre_release_notifications"

    init() {
        let data = userDefaults.data(forKey: storageKey)

        self.notifications = data.flatMap { try? JSONDecoder().decode([PreReleaseNotification].self, from: $0) } ?? []
    }

    func fetchAll() async -> [PreReleaseNotification] {
        notifications.filter(\.isValidForScheduling)
    }

    func fetch(for bookId: Book.ID) async -> PreReleaseNotification? {
        notifications.first { $0.bookId == bookId }
    }

    func add(_ notification: PreReleaseNotification) async {
        notifications.removeAll { $0.bookId == notification.bookId }
        notifications.append(notification)
        saveToUserDefaults()
    }

    func remove(for bookId: Book.ID) async {
        notifications.removeAll { $0.bookId == bookId }
        saveToUserDefaults()
    }

    func update(_ notification: PreReleaseNotification) async {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index] = notification
            saveToUserDefaults()
        }
    }

    func removeExpiredNotifications() async {
        let currentDate = Date()
        notifications.removeAll { notification in
            guard let releaseDate = notification.releaseDate as Date? else { return false }
            return releaseDate <= currentDate
        }
        saveToUserDefaults()
    }

    private func saveToUserDefaults() {
        guard let data = try? JSONEncoder().encode(notifications) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
