public import Dependencies

import Foundation
import DependenciesMacros

@DependencyClient
public struct WidgetUpdater: Sendable {
    public var setNeedNotify: @Sendable () async -> Void
    public var notifyIfNeed: @Sendable () async -> Void
}

extension WidgetUpdater: DependencyKey {
    public static let liveValue: WidgetUpdater = .init()
}
