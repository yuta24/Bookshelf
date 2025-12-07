import Foundation

/// Tracks data migration progress to ensure one-time execution
public struct MigrationTracker: Sendable {
    private enum Key {
        static let swiftDataToGRDBCompleted = "swiftdata_to_grdb_migration_completed"
        static let migrationVersion = "migration_version"
    }

    private let userDefaults: @Sendable () -> UserDefaults

    public init(userDefaults: @escaping @Sendable () -> UserDefaults = { .standard }) {
        self.userDefaults = userDefaults
    }

    /// Check if SwiftData to GRDB migration has been completed
    public func isSwiftDataMigrationCompleted() -> Bool {
        userDefaults().bool(forKey: Key.swiftDataToGRDBCompleted)
    }

    /// Mark SwiftData to GRDB migration as completed
    public func markSwiftDataMigrationCompleted() {
        userDefaults().set(true, forKey: Key.swiftDataToGRDBCompleted)
        userDefaults().set(1, forKey: Key.migrationVersion)
        userDefaults().synchronize()
    }

    /// Check if migration is required based on SwiftData database existence and migration status
    public func requiresMigration(from swiftDataURL: URL, fileManager: FileManager = .default) -> Bool {
        // If migration already completed, no need to migrate again
        if isSwiftDataMigrationCompleted() {
            return false
        }

        // Check if SwiftData database file exists and has data
        guard fileManager.fileExists(atPath: swiftDataURL.path) else {
            // No SwiftData database, this is a fresh install
            markSwiftDataMigrationCompleted()
            return false
        }

        // SwiftData database exists and migration not completed yet
        return true
    }

    /// Reset migration status (useful for testing)
    public func resetMigrationStatus() {
        userDefaults().removeObject(forKey: Key.swiftDataToGRDBCompleted)
        userDefaults().removeObject(forKey: Key.migrationVersion)
        userDefaults().synchronize()
    }
}
