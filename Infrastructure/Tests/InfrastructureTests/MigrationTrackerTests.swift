import Testing
import Foundation
@testable import Infrastructure

extension UserDefaults: @unchecked @retroactive Sendable {}

/// Tests for MigrationTracker functionality
@Suite("MigrationTracker Tests")
struct MigrationTrackerTests {

    // MARK: - Helper Methods

    /// Create a temporary UserDefaults for testing
    private func createTestUserDefaults() -> UserDefaults {
        let suiteName = "test.migration.tracker.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        // Clear any existing data
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    /// Create a temporary file URL for testing
    private func createTempFileURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("test-\(UUID().uuidString).sqlite")
    }

    // MARK: - Fresh Install Tests

    @Test("Fresh install: No SwiftData DB should auto-complete migration")
    func freshInstallAutoCompletes() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })
        let mockFileManager = MockFileManager(fileExists: false)
        let swiftDataURL = createTempFileURL()

        // Fresh install should not require migration
        let requiresMigration = tracker.requiresMigration(
            from: swiftDataURL,
            fileManager: mockFileManager
        )

        #expect(!requiresMigration)
        #expect(tracker.isSwiftDataMigrationCompleted())
    }

    @Test("Fresh install: Migration should be marked as completed")
    func freshInstallMarksCompleted() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })

        #expect(!tracker.isSwiftDataMigrationCompleted())

        let mockFileManager = MockFileManager(fileExists: false)
        let swiftDataURL = createTempFileURL()

        _ = tracker.requiresMigration(from: swiftDataURL, fileManager: mockFileManager)

        #expect(tracker.isSwiftDataMigrationCompleted())
    }

    // MARK: - Migration Required Tests

    @Test("Existing data: SwiftData DB exists and not migrated should require migration")
    func existingDataRequiresMigration() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })
        let mockFileManager = MockFileManager(fileExists: true)
        let swiftDataURL = createTempFileURL()

        let requiresMigration = tracker.requiresMigration(
            from: swiftDataURL,
            fileManager: mockFileManager
        )

        #expect(requiresMigration)
        #expect(!tracker.isSwiftDataMigrationCompleted())
    }

    // MARK: - Migration Completed Tests

    @Test("Mark migration completed")
    func markMigrationCompleted() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })

        #expect(!tracker.isSwiftDataMigrationCompleted())

        tracker.markSwiftDataMigrationCompleted()

        #expect(tracker.isSwiftDataMigrationCompleted())
    }

    @Test("Already completed: Should not require migration even with DB present")
    func alreadyCompletedDoesNotRequireMigration() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })
        let mockFileManager = MockFileManager(fileExists: true)
        let swiftDataURL = createTempFileURL()

        // Mark as completed
        tracker.markSwiftDataMigrationCompleted()

        let requiresMigration = tracker.requiresMigration(
            from: swiftDataURL,
            fileManager: mockFileManager
        )

        #expect(!requiresMigration)
        #expect(tracker.isSwiftDataMigrationCompleted())
    }

    // MARK: - Version Tracking Tests

    @Test("Version tracking: Should store migration version")
    func migrationVersionTracking() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })

        tracker.markSwiftDataMigrationCompleted()

        let version = defaults.integer(forKey: "migration_version")
        #expect(version == 1)
    }

    // MARK: - Reset Tests

    @Test("Reset migration: Can reset and require migration again")
    func resetMigration() throws {
        let defaults = createTestUserDefaults()
        let tracker = MigrationTracker(userDefaults: { defaults })
        let mockFileManager = MockFileManager(fileExists: true)
        let swiftDataURL = createTempFileURL()

        // Complete migration
        tracker.markSwiftDataMigrationCompleted()
        #expect(tracker.isSwiftDataMigrationCompleted())

        // Reset
        defaults.removeObject(forKey: "swiftdata_to_grdb_migration_completed")

        // Should require migration again
        let requiresMigration = tracker.requiresMigration(
            from: swiftDataURL,
            fileManager: mockFileManager
        )

        #expect(requiresMigration)
        #expect(!tracker.isSwiftDataMigrationCompleted())
    }
}

// MARK: - Mock FileManager

/// Mock FileManager for testing file existence checks
private final class MockFileManager: FileManager {
    private let _fileExists: Bool

    init(fileExists: Bool) {
        self._fileExists = fileExists
    }

    override func fileExists(atPath path: String) -> Bool {
        return _fileExists
    }
}
