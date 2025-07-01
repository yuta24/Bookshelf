public import Dependencies
public import BookModel

import Foundation
import DependenciesMacros

@DependencyClient
public struct TagClient: Sendable {
    public var create: @Sendable (CreatingTag) async throws -> Tag
    public var fetchAll: @Sendable () async throws -> [Tag]
    public var update: @Sendable (Tag) async throws -> Tag
    public var delete: @Sendable (Tag.ID) async throws -> Void
    public var exists: @Sendable (String) async throws -> Bool
}

extension TagClient: DependencyKey {
    public static let liveValue: TagClient = .init()
}
