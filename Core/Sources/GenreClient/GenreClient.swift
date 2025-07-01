public import Dependencies
public import GenreModel

import Foundation
import DependenciesMacros

@DependencyClient
public struct GenreClient: Sendable {
    public var fetch: @Sendable () async throws -> [Genre]
}

extension GenreClient: DependencyKey {
    public static let liveValue: GenreClient = .init()
}
