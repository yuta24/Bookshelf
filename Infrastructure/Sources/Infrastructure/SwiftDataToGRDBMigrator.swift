import Foundation
@preconcurrency import SwiftData
import SQLiteData
import OSLog
import BookModel
import BookRecord

private let logger = Logger(subsystem: "com.bivre.bookshelf", category: "Migration")

/// Result of migration operation
public struct MigrationResult {
    public let booksConverted: Int
    public let tagsConverted: Int
    public let booksSkipped: Int
    public let tagsSkipped: Int
    public let associations: Int

    public var totalConverted: Int {
        booksConverted + tagsConverted
    }

    public var totalSkipped: Int {
        booksSkipped + tagsSkipped
    }
}

/// Service for migrating data from SwiftData to GRDB
public struct SwiftDataToGRDBMigrator: Sendable {
    private let swiftDataContext: ModelContext
    private let grdbDatabase: any DatabaseWriter

    public init(swiftDataContext: ModelContext, grdbDatabase: any DatabaseWriter) {
        self.swiftDataContext = swiftDataContext
        self.grdbDatabase = grdbDatabase
    }

    /// Count the number of books to migrate
    public func countBooksToMigrate() async throws -> Int {
        let descriptor = FetchDescriptor<BookRecord>()
        return try swiftDataContext.fetchCount(descriptor)
    }

    /// Migrate data from SwiftData to GRDB with progress reporting
    ///
    /// - Parameter progressHandler: Closure called with (current, total) for progress updates during read/conversion phase
    /// - Throws: Migration errors. All database writes are performed in a single atomic transaction and automatically rolled back on error.
    public func migrate(
        progressHandler: @escaping @Sendable (Int, Int) async -> Void
    ) async throws {
        logger.info("Starting SwiftData to GRDB migration...")

        // Step 1: Extract data from SwiftData
        let (bookRecords, tagRecords) = try await Self.extractSwiftDataRecords(from: swiftDataContext)
        let totalItems = bookRecords.count + tagRecords.count

        logger.info("Extracted \(bookRecords.count) books and \(tagRecords.count) tags from SwiftData")

        // Step 2: Convert records to GRDB models
        let (book2s, booksSkipped) = Self.convertBooks(bookRecords)
        let (tag2s, tagsSkipped) = Self.convertTags(tagRecords)
        let rawAssociations = RecordConversion.extractBookTagAssociations(bookRecords)

        // Filter associations to only include tags that were successfully converted
        let validTagIds = Set(tag2s.map { $0.id })
        let associations = rawAssociations.mapValues { tagIds in
            tagIds.filter { validTagIds.contains($0) }
        }.filter { !$0.value.isEmpty }

        logger.info("Converted \(book2s.count) books (skipped \(booksSkipped)) and \(tag2s.count) tags (skipped \(tagsSkipped))")

        if booksSkipped > 0 || tagsSkipped > 0 {
            logger.warning("Skipped \(booksSkipped) books and \(tagsSkipped) tags due to missing required fields")
        }

        // Step 3: Write to GRDB in a single atomic transaction
        try await Self.writeToGRDB(
            books: book2s,
            tags: tag2s,
            associations: associations,
            database: grdbDatabase,
            progressHandler: progressHandler,
            totalItems: totalItems
        )

        logger.info("Migration completed successfully")
    }

    /// Migrate data from SwiftData to GRDB in an atomic transaction (static version for backward compatibility)
    ///
    /// - Parameters:
    ///   - swiftDataController: Source PersistenceController containing SwiftData
    ///   - grdbDatabase: Target GRDB DatabaseWriter
    /// - Returns: MigrationResult with statistics
    /// - Throws: Migration errors. All database writes are performed in a single atomic transaction and automatically rolled back on error.
    public static func migrate(
        from swiftDataController: PersistenceController,
        to grdbDatabase: any DatabaseWriter
    ) async throws -> MigrationResult {
        let context = swiftDataController.context
        logger.info("Starting SwiftData to GRDB migration...")

        // Step 1: Extract data from SwiftData
        let (bookRecords, tagRecords) = try await extractSwiftDataRecords(from: swiftDataController)

        logger.info("Extracted \(bookRecords.count) books and \(tagRecords.count) tags from SwiftData")

        // Step 2: Convert records to GRDB models
        let (book2s, booksSkipped) = convertBooks(bookRecords)
        let (tag2s, tagsSkipped) = convertTags(tagRecords)
        let rawAssociations = RecordConversion.extractBookTagAssociations(bookRecords)

        // Filter associations to only include tags that were successfully converted
        let validTagIds = Set(tag2s.map { $0.id })
        let associations = rawAssociations.mapValues { tagIds in
            tagIds.filter { validTagIds.contains($0) }
        }.filter { !$0.value.isEmpty }

        logger.info("Converted \(book2s.count) books (skipped \(booksSkipped)) and \(tag2s.count) tags (skipped \(tagsSkipped))")

        if booksSkipped > 0 || tagsSkipped > 0 {
            logger.warning("Skipped \(booksSkipped) books and \(tagsSkipped) tags due to missing required fields")
        }

        // Step 3: Write to GRDB in a single atomic transaction
        try await writeToGRDB(
            books: book2s,
            tags: tag2s,
            associations: associations,
            database: grdbDatabase
        )

        let result = MigrationResult(
            booksConverted: book2s.count,
            tagsConverted: tag2s.count,
            booksSkipped: booksSkipped,
            tagsSkipped: tagsSkipped,
            associations: associations.values.map { $0.count }.reduce(0, +)
        )

        logger.info("Migration completed successfully: \(result.totalConverted) records converted, \(result.totalSkipped) skipped")

        return result
    }

    // MARK: - Private Helper Methods

    /// Extract all records from SwiftData
    private static func extractSwiftDataRecords(
        from context: ModelContext
    ) async throws -> ([BookRecord], [TagRecord]) {
        // Fetch all book records
        let bookDescriptor = FetchDescriptor<BookRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let bookRecords = try context.fetch(bookDescriptor)

        // Fetch all tag records
        let tagDescriptor = FetchDescriptor<TagRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let tagRecords = try context.fetch(tagDescriptor)

        return (bookRecords, tagRecords)
    }

    /// Extract all records from SwiftData (overload for PersistenceController)
    private static func extractSwiftDataRecords(
        from controller: PersistenceController
    ) async throws -> ([BookRecord], [TagRecord]) {
        try await extractSwiftDataRecords(from: controller.context)
    }

    /// Convert BookRecords to Book2 models, skipping invalid records
    private static func convertBooks(_ records: [BookRecord]) -> (books: [Book2], skipped: Int) {
        var books: [Book2] = []
        var skipped = 0

        for record in records {
            do {
                let book2 = try RecordConversion.convertToBook2(record)
                books.append(book2)
            } catch {
                logger.warning("Skipping book due to conversion error: \(error.localizedDescription)")
                skipped += 1
            }
        }

        return (books, skipped)
    }

    /// Convert TagRecords to Tag2 models, skipping invalid records
    private static func convertTags(_ records: [TagRecord]) -> (tags: [Tag2], skipped: Int) {
        var tags: [Tag2] = []
        var skipped = 0

        for record in records {
            do {
                let tag2 = try RecordConversion.convertToTag2(record)
                tags.append(tag2)
            } catch {
                logger.warning("Skipping tag due to conversion error: \(error.localizedDescription)")
                skipped += 1
            }
        }

        return (tags, skipped)
    }

    /// Write all data to GRDB in a single atomic transaction
    /// - Note: All writes are performed in one transaction. If any write fails, all changes are automatically rolled back.
    private static func writeToGRDB(
        books: [Book2],
        tags: [Tag2],
        associations: [UUID: [UUID]],
        database: any DatabaseWriter,
        progressHandler: (@Sendable (Int, Int) async -> Void)? = nil,
        totalItems: Int = 0
    ) async throws {
        let totalAssociations = associations.values.map { $0.count }.reduce(0, +)
        let totalOperations = tags.count + books.count + totalAssociations
        var currentProgress = 0

        // Execute all writes in a single atomic transaction
        try await database.write { db in
            // Insert tags first (books reference tags)
            for (index, tag) in tags.enumerated() {
                try Tag2.insert { tag }.execute(db)

                currentProgress += 1
                if let progressHandler = progressHandler, (index + 1) % 10 == 0 || index == tags.count - 1 {
                    await progressHandler(currentProgress, totalOperations)
                }
            }
            logger.debug("Inserted \(tags.count) tags")

            // Insert books
            for (index, book) in books.enumerated() {
                try Book2.insert { book }.execute(db)

                currentProgress += 1
                if let progressHandler = progressHandler, (index + 1) % 10 == 0 || index == books.count - 1 {
                    await progressHandler(currentProgress, totalOperations)
                }
            }
            logger.debug("Inserted \(books.count) books")

            // Insert book-tag associations
            var associationCount = 0
            for (bookId, tagIds) in associations {
                for tagId in tagIds {
                    let bookTag = BookTag2(id: .init(), bookId: bookId, tagId: tagId)

                    try BookTag2.insert { bookTag }.execute(db)

                    associationCount += 1
                    currentProgress += 1
                    if let progressHandler = progressHandler, associationCount % 10 == 0 || currentProgress == totalOperations {
                        await progressHandler(currentProgress, totalOperations)
                    }
                }
            }
            logger.debug("Inserted \(associationCount) book-tag associations")
        }
        // Transaction automatically commits if no error occurred, or rolls back if any error was thrown

        // Ensure final progress is reported
        if let progressHandler = progressHandler {
            await progressHandler(totalOperations, totalOperations)
        }

        logger.info("Successfully wrote all data to GRDB")
    }
}
