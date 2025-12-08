import Foundation
import SQLiteData
import BookModel

/// Create an in-memory GRDB database for testing
public func createTestDatabase() throws -> any DatabaseWriter {
    var configuration = Configuration()

    #if DEBUG
    configuration.prepareDatabase { db in
        db.trace(options: .profile) { event in
            print(event.expandedDescription)
        }
    }
    #endif

    // Create in-memory database
    let database = try DatabaseQueue(configuration: configuration)

    var migrator = DatabaseMigrator()

    // Register the same migrations as production
    migrator.registerMigration("Create tables") { db in
        try #sql("""
        CREATE TABLE "tags"(
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
          "name" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "created_at" TEXT NOT NULL,
          "updated_at" TEXT NOT NULL
        ) STRICT
        """)
        .execute(db)

        try #sql("""
        CREATE TABLE "books"(
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
          "title" TEXT NOT NULL,
          "author" TEXT NOT NULL,
          "price" INTEGER,
          "affiliate_url" TEXT NOT NULL,
          "image_url" TEXT NOT NULL,
          "isbn" TEXT NOT NULL,
          "publisher" TEXT NOT NULL,
          "caption" TEXT NOT NULL,
          "sales_at" TEXT NOT NULL,
          "bought" INTEGER NOT NULL ON CONFLICT REPLACE DEFAULT 0,
          "note" TEXT NOT NULL ON CONFLICT REPLACE DEFAULT '',
          "status" TEXT NOT NULL,
          "read_at" TEXT NOT NULL,
          "created_at" TEXT NOT NULL,
          "updated_at" TEXT NOT NULL
        ) STRICT
        """)
        .execute(db)

        try #sql("""
        CREATE TABLE "book_tags"(
          "id" TEXT PRIMARY KEY NOT NULL ON CONFLICT REPLACE DEFAULT (uuid()),
          "book_id" TEXT NOT NULL REFERENCES "books"("id") ON DELETE CASCADE,
          "tag_id"  TEXT NOT NULL REFERENCES "tags"("id") ON DELETE CASCADE
        ) STRICT
        """).execute(db)
    }

    try migrator.migrate(database)

    return database
}

/// Helper to verify database state in tests
public extension DatabaseReader {
    /// Count rows in a table
    func countRows(in table: String) throws -> Int {
        try read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM \(table)") ?? 0
        }
    }

    /// Check if a book exists by ID
    func bookExists(id: UUID) async throws -> Bool {
        try await read { db in
            try Book2.where { $0.id == id }.fetchCount(db) > 0
        }
    }

    /// Check if a tag exists by ID
    func tagExists(id: UUID) async throws -> Bool {
        try await read { db in
            try Tag2.where { $0.id == id }.fetchCount(db) > 0
        }
    }

    /// Fetch all books
    func fetchAllBooks() async throws -> [Book2] {
        try await read { db in
            try Book2.all.fetchAll(db)
        }
    }

    /// Fetch all tags
    func fetchAllTags() async throws -> [Tag2] {
        try await read { db in
            try Tag2.all.fetchAll(db)
        }
    }

    /// Count book-tag associations
    func countBookTagAssociations() async throws -> Int {
        try await read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM book_tags") ?? 0
        }
    }
}
