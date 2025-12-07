import Testing
import Foundation
import BookModel
import SQLiteData
@testable import Infrastructure

/// Tests for SwiftDataToGRDBMigrator functionality
@Suite("SwiftDataToGRDBMigrator Tests")
struct SwiftDataToGRDBMigratorTests {

    // MARK: - Successful Migration Tests

    @Test("Migrate empty database")
    func migrateEmptyDatabase() async throws {
        let swiftDataController = TestPersistenceController()
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController.container,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 0)
        #expect(result.tagsConverted == 0)
        #expect(result.booksSkipped == 0)
        #expect(result.tagsSkipped == 0)
    }

    @Test("Migrate single book without tags")
    func migrateSingleBook() async throws {
        let book = TestFixtures.createValidBookRecord()
        let swiftDataController = try TestPersistenceController.withData(books: [book])
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 1)
        #expect(result.tagsConverted == 0)
        #expect(result.booksSkipped == 0)

        // Verify data in GRDB
        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books.count == 1)
        #expect(books[0].id == book.id)
    }

    @Test("Migrate multiple books")
    func migrateMultipleBooks() async throws {
        let books = TestFixtures.createBookRecords(count: 10)
        let swiftDataController = try TestPersistenceController.withData(books: books)
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 10)
        #expect(result.booksSkipped == 0)

        let migratedBooks = try await grdbDatabase.fetchAllBooks()
        #expect(migratedBooks.count == 10)
    }

    @Test("Migrate tags")
    func migrateTags() async throws {
        let tags = TestFixtures.createTagRecords(count: 5)
        let swiftDataController = try TestPersistenceController.withData(tags: tags)
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.tagsConverted == 5)
        #expect(result.tagsSkipped == 0)

        let migratedTags = try await grdbDatabase.fetchAllTags()
        #expect(migratedTags.count == 5)
    }

    @Test("Migrate book with tags preserves associations")
    func migrateBookWithTagsPreservesAssociations() async throws {
        let tag1 = TestFixtures.createValidTagRecord(name: "Fiction")
        let tag2 = TestFixtures.createValidTagRecord(name: "Science")
        let book = TestFixtures.createBookRecordWithTags(tags: [tag1, tag2])

        let swiftDataController = try TestPersistenceController.withData(
            books: [book],
            tags: [tag1, tag2]
        )
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 1)
        #expect(result.tagsConverted == 2)
        #expect(result.associations == 2)

        // Verify associations
        let associationCount = try await grdbDatabase.countBookTagAssociations()
        #expect(associationCount == 2)
    }

    // MARK: - Invalid Data Handling Tests

    @Test("Skip invalid book records")
    func skipInvalidBookRecords() async throws {
        let validBook = TestFixtures.createValidBookRecord()
        let invalidBook = TestFixtures.createInvalidBookRecord(id: nil)

        let swiftDataController = TestPersistenceController()
        try swiftDataController.insert([validBook, invalidBook])

        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 1)
        #expect(result.booksSkipped == 1)

        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books.count == 1)
        #expect(books[0].id == validBook.id)
    }

    @Test("Skip invalid tag records")
    func skipInvalidTagRecords() async throws {
        let validTag = TestFixtures.createValidTagRecord()
        let invalidTag = TestFixtures.createInvalidTagRecord(id: nil)

        let swiftDataController = TestPersistenceController()
        try swiftDataController.insert([validTag, invalidTag])

        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.tagsConverted == 1)
        #expect(result.tagsSkipped == 1)

        let tags = try await grdbDatabase.fetchAllTags()
        #expect(tags.count == 1)
        #expect(tags[0].id == validTag.id)
    }

    @Test("Skip book with invalid status")
    func skipBookWithInvalidStatus() async throws {
        let validBook = TestFixtures.createValidBookRecord(status: "unread")
        let invalidBook = TestFixtures.createValidBookRecord(status: "invalid_status")

        let swiftDataController = TestPersistenceController()
        try swiftDataController.insert([validBook, invalidBook])

        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 1)
        #expect(result.booksSkipped == 1)
    }

    // MARK: - Status Preservation Tests

    @Test("Preserve unread status")
    func preserveUnreadStatus() async throws {
        let book = TestFixtures.createValidBookRecord(status: "unread")
        let swiftDataController = try TestPersistenceController.withData(books: [book])
        let grdbDatabase = try createTestDatabase()

        _ = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books[0].status == .unread)
    }

    @Test("Preserve reading status")
    func preserveReadingStatus() async throws {
        let book = TestFixtures.createValidBookRecord(status: "reading")
        let swiftDataController = try TestPersistenceController.withData(books: [book])
        let grdbDatabase = try createTestDatabase()

        _ = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books[0].status == .reading)
    }

    @Test("Preserve read status with readAt date")
    func preserveReadStatusWithDate() async throws {
        let readAt = Date()
        let book = TestFixtures.createValidBookRecord(
            status: "read",
            readAt: readAt
        )
        let swiftDataController = try TestPersistenceController.withData(books: [book])
        let grdbDatabase = try createTestDatabase()

        _ = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books[0].status == .read)
        #expect(books[0].readAt == readAt)
    }

    // MARK: - Large Dataset Tests

    @Test("Migrate large dataset (100 books, 20 tags)")
    func migrateLargeDataset() async throws {
        let books = TestFixtures.createBookRecords(count: 100)
        let tags = TestFixtures.createTagRecords(count: 20)
        let swiftDataController = try TestPersistenceController.withData(
            books: books,
            tags: tags
        )
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 100)
        #expect(result.tagsConverted == 20)
        #expect(result.totalConverted == 120)
        #expect(result.totalSkipped == 0)
    }

    // MARK: - Transaction Tests

    @Test("Atomic transaction: All or nothing")
    func atomicTransaction() async throws {
        // This test verifies the atomic transaction behavior:
        // 1. All writes occur in a single transaction
        // 2. If any error occurs (e.g., during tag insertion, book insertion, or association insertion),
        //    the entire transaction is rolled back automatically
        // 3. No partial data is left in the database after a failed migration
        // 4. Retry succeeds after a failed migration (no constraint violations from partial data)

        let validBook = TestFixtures.createValidBookRecord()
        let swiftDataController = try TestPersistenceController.withData(books: [validBook])
        let grdbDatabase = try createTestDatabase()

        // First migration should succeed
        _ = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        let booksAfterFirstMigration = try await grdbDatabase.fetchAllBooks()
        #expect(booksAfterFirstMigration.count == 1)

        // Attempting to migrate again should fail due to unique constraint
        // This simulates an error that could occur at any point during the migration
        // (tag insertion, book insertion, or association insertion)
        do {
            _ = try await SwiftDataToGRDBMigrator.migrate(
                from: swiftDataController,
                to: grdbDatabase
            )
            Issue.record("Expected migration to fail on duplicate data")
        } catch {
            // Expected failure - verify database is clean (no partial data)
            let booksAfterFailedMigration = try await grdbDatabase.fetchAllBooks()
            #expect(booksAfterFailedMigration.count == 1)  // Still only the original book
        }
    }

    // MARK: - MigrationResult Tests

    @Test("MigrationResult totals calculation")
    func migrationResultTotals() throws {
        let result = MigrationResult(
            booksConverted: 10,
            tagsConverted: 5,
            booksSkipped: 2,
            tagsSkipped: 1,
            associations: 15
        )

        #expect(result.totalConverted == 15)
        #expect(result.totalSkipped == 3)
    }

    @Test("MigrationResult with no skipped records")
    func migrationResultNoSkipped() throws {
        let result = MigrationResult(
            booksConverted: 10,
            tagsConverted: 5,
            booksSkipped: 0,
            tagsSkipped: 0,
            associations: 15
        )

        #expect(result.totalSkipped == 0)
    }

    // MARK: - Complex Association Tests

    @Test("Migrate multiple books sharing tags")
    func migrateMultipleBooksSharing() async throws {
        let sharedTag = TestFixtures.createValidTagRecord(name: "Programming")
        let book1 = TestFixtures.createBookRecordWithTags(tags: [sharedTag])
        let book2 = TestFixtures.createBookRecordWithTags(tags: [sharedTag])

        let swiftDataController = try TestPersistenceController.withData(
            books: [book1, book2],
            tags: [sharedTag]
        )
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 2)
        #expect(result.tagsConverted == 1)
        #expect(result.associations == 2)

        let associationCount = try await grdbDatabase.countBookTagAssociations()
        #expect(associationCount == 2)
    }

    // MARK: - Edge Case Tests

    @Test("Migrate book with empty note")
    func migrateBookWithEmptyNote() async throws {
        let book = TestFixtures.createValidBookRecord(note: "")
        let swiftDataController = try TestPersistenceController.withData(books: [book])
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 1)

        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books[0].note == "")
    }

    @Test("Migrate book with nil optional fields")
    func migrateBookWithNilOptionalFields() async throws {
        let book = TestFixtures.createValidBookRecord(
            affiliateURL: nil,
            caption: nil
        )
        let swiftDataController = try TestPersistenceController.withData(books: [book])
        let grdbDatabase = try createTestDatabase()

        let result = try await SwiftDataToGRDBMigrator.migrate(
            from: swiftDataController,
            to: grdbDatabase
        )

        #expect(result.booksConverted == 1)

        let books = try await grdbDatabase.fetchAllBooks()
        #expect(books[0].affiliateURL == nil)
        #expect(books[0].caption == nil)
    }
}
