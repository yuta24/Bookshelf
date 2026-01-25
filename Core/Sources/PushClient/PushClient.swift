import UserNotifications
import Dependencies
import Foundation
import DependenciesMacros

@DependencyClient
public struct PushClient: Sendable {
    public var register: @Sendable () async throws -> Void
    public var request: @Sendable () async throws -> Bool
    public var notificationSettings: @Sendable () async -> UNNotificationSettings = { { fatalError() }() }
}

extension PushClient: DependencyKey {
    public static let liveValue: PushClient = .init()
}
