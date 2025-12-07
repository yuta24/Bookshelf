public import Dependencies
import Foundation
import DependenciesMacros

@DependencyClient
public struct MigrationClient: Sendable {
    /// Check if migration from SwiftData to GRDB has been completed
    public var isCompleted: @Sendable () -> Bool = { false }

    /// Check if migration from SwiftData to GRDB is required
    public var requiresMigration: @Sendable () async throws -> Bool

    /// Get the count of books to migrate
    public var getBookCount: @Sendable () async throws -> Int

    /// Perform migration from SwiftData to GRDB
    public var performMigration: @Sendable (@escaping @Sendable (Int, Int) async -> Void) async throws -> Void

    /// Mark migration as completed
    public var markCompleted: @Sendable () async throws -> Void
}

extension MigrationClient: DependencyKey {
    public static let liveValue: MigrationClient = .init()
}

extension DependencyValues {
    public var migrationClient: MigrationClient {
        get { self[MigrationClient.self] }
        set { self[MigrationClient.self] = newValue }
    }
}
