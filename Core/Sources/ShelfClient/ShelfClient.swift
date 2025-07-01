public import Dependencies
public import BookModel

import Foundation
import DependenciesMacros

@DependencyClient
public struct ShelfClient: Sendable {
    public enum Filter: Sendable {
        case status(Book.Status)
    }

    public var create: @Sendable (SearchingBook) async throws -> Book
    public var fetchAll: @Sendable (_ filter: Filter?) async throws -> [Book]
    public var fetch: @Sendable (Book.ID) async throws -> Book?
    public var update: @Sendable (Book) async throws -> Book
    public var delete: @Sendable (Book.ID) async throws -> Void
    public var exists: @Sendable (Book.ISBN) async throws -> Bool
    public var resume: @Sendable ([Book]) async throws -> Void

    public var fetchAtYear: @Sendable (_ year: Int) async throws -> [Book]
    public var countAtYear: @Sendable (_ year: Int) async throws -> (unread: Int, reading: Int, read: Int)
}

extension ShelfClient: DependencyKey {
    public static let liveValue: ShelfClient = .init()
}
