public import Foundation
public import UIKit
public import Dependencies

import DependenciesMacros

@DependencyClient
@available(iOSApplicationExtension, unavailable)
public struct Application: Sendable {
    public var identifier: @Sendable () -> String = { unimplemented("Application.identifier", placeholder: "com.bivre.bookshelf") }
    public var build: @Sendable () -> Int = { unimplemented("Application.build", placeholder: 1) }
    public var version: @Sendable () -> String = { unimplemented("Application.version", placeholder: "0.1.0") }
    public var open: @MainActor @Sendable (URL, [UIApplication.OpenExternalURLOptionsKey: Any], ((Bool) -> Void)?) -> Void
}

extension Application: DependencyKey {
    public static let liveValue: Application = .init()
}
