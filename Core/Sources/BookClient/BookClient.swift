public import Foundation
public import Dependencies

public import BookModel

public import GenreModel

import DependenciesMacros

@DependencyClient
public struct BookClient: Sendable {
    public enum Kind {
        case new
        case sales
    }

    public var fetch: @Sendable (_ genre: Genre?, _ kind: Kind) async throws -> ([SearchingBook], HTTPURLResponse)
}

extension BookClient: DependencyKey {
    public static let liveValue: BookClient = .init()
}
