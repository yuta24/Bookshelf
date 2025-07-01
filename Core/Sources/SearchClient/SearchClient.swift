public import Foundation
public import Dependencies

public import BookModel

import DependenciesMacros

@DependencyClient
public struct SearchClient: Sendable {
    public enum By {
        case title(String)
        case isbn(String)
    }

    public var search: @Sendable (_ by: By) async throws -> ([SearchingBook], HTTPURLResponse)
}

extension SearchClient: DependencyKey {
    public static let liveValue: SearchClient = .init()
}
