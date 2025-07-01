public import Dependencies

import Foundation
import DependenciesMacros

@DependencyClient
public struct FeatureFlags: Sendable {
    public var enableNotification: @Sendable () -> Bool = { unimplemented("FeatureFlag.enableNotification", placeholder: false) }
    public var enableBooks: @Sendable () -> Bool = { unimplemented("FeatureFlag.enableBooks", placeholder: false) }
    public var enablePurchase: @Sendable () -> Bool = { unimplemented("FeatureFlag.enablePurchase", placeholder: false) }
    public var enableImport: @Sendable () -> Bool = { unimplemented("FeatureFlag.enableImport", placeholder: false) }
    public var enableExport: @Sendable () -> Bool = { unimplemented("FeatureFlag.enableExport", placeholder: false) }
}

extension FeatureFlags: DependencyKey {
    public static let liveValue: FeatureFlags = .init()
}
