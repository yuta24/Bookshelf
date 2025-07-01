public import SyncModel
public import Dependencies

import Foundation
import DependenciesMacros

@DependencyClient
public struct SyncClient: Sendable {
    public var fetch: @Sendable () -> Sync?
    public var update: @Sendable (Sync) -> Void
}

extension SyncClient: DependencyKey {
    public static let liveValue: SyncClient = .init()
}
