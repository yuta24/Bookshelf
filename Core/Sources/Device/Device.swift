public import Dependencies
import Foundation
import DependenciesMacros

@DependencyClient
public struct Device: Sendable {
    public var isProfileInstalled: @Sendable () -> Bool = { unimplemented("Device.isProfileInstalled", placeholder: false) }
}

extension Device: DependencyKey {
    public static let liveValue: Device = .init()
}
