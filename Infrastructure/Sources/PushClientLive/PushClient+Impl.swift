public import PushClient

import UIKit

public extension PushClient {
    static func generate() -> PushClient {
        .init(
            register: {
                await UIApplication.shared.registerForRemoteNotifications()
            },
            request: {
                try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            },
            notificationSettings: {
                await UNUserNotificationCenter.current().notificationSettings()
            }
        )
    }
}
