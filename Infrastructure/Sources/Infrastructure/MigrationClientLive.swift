public import MigrationCore
import Foundation
import GRDB
import SwiftData

public extension MigrationClient {
    static func generate(
        persistence: PersistenceController,
        grdbDatabase: any DatabaseWriter,
        fileManager: @escaping @Sendable () -> FileManager = { .default }
    ) -> Self {
        let tracker = MigrationTracker()
        let migrator = SwiftDataToGRDBMigrator(
            swiftDataContext: persistence.context,
            grdbDatabase: grdbDatabase
        )

        return .init(
            isCompleted: {
                tracker.isSwiftDataMigrationCompleted()
            },
            requiresMigration: {
                // Get SwiftData store URL
                guard let storeURL = persistence.context.container.configurations.first?.url else {
                    return false
                }

                return tracker.requiresMigration(from: storeURL, fileManager: fileManager())
            },
            getBookCount: {
                try await migrator.countBooksToMigrate()
            },
            performMigration: { progressHandler in
                try await migrator.migrate(progressHandler: progressHandler)
            },
            markCompleted: {
                tracker.markSwiftDataMigrationCompleted()
            }
        )
    }
}
