public import Dependencies
public import PreReleaseNotificationModel
public import BookModel

import Foundation
import DependenciesMacros

@DependencyClient
public struct PreReleaseNotificationClient: Sendable {
    public var fetchAll: @Sendable () async -> [PreReleaseNotification] = { [] }
    public var fetch: @Sendable (Book.ID) async -> PreReleaseNotification? = { _ in nil }
    public var add: @Sendable (PreReleaseNotification) async -> Void
    public var remove: @Sendable (Book.ID) async -> Void
    public var update: @Sendable (PreReleaseNotification) async -> Void
    public var scheduleNotification: @Sendable (PreReleaseNotification) async -> Void
    public var cancelNotification: @Sendable (String) async -> Void
    public var removeExpiredNotifications: @Sendable () async -> Void
}

extension PreReleaseNotificationClient: DependencyKey {
    public static let liveValue: PreReleaseNotificationClient = .init()
}
