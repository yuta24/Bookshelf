public import UserNotifications

public import Dependencies

import Foundation

public struct PushClient: Sendable {
    public var register: @Sendable () async throws -> Void
    public var request: @Sendable () async throws -> Bool
    public var notificationSettings: @Sendable () async -> UNNotificationSettings

    public init(
        register: @escaping @Sendable () async throws -> Void,
        request: @escaping @Sendable () async throws -> Bool,
        notificationSettings: @escaping @Sendable () async -> UNNotificationSettings
    ) {
        self.register = register
        self.request = request
        self.notificationSettings = notificationSettings
    }
}

private enum PushClientKey: DependencyKey {
    static let liveValue: PushClient = .init(
        register: unimplemented("PushClient.register"),
        request: unimplemented("PushClient.request", placeholder: false),
        notificationSettings: unimplemented("PushClient.notificationSettings", placeholder: UNNotificationSettings(coder: NSCoder())!)
    )
}

public extension DependencyValues {
    var pushClient: PushClient {
        get { self[PushClientKey.self] }
        set { self[PushClientKey.self] = newValue }
    }
}
