public import Dependencies
public import RemindModel

import Foundation
import DependenciesMacros

@DependencyClient
public struct RemindClient: Sendable {
    public var fetch: @Sendable () -> Remind = { unimplemented("RemindClient.fetch", placeholder: .disabled) }
    public var update: @Sendable (Remind) -> Void
}

extension RemindClient: DependencyKey {
    public static let liveValue: RemindClient = .init()
}
