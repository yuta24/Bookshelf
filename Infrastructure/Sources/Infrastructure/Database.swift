import OSLog
import SQLiteData

private let logger = Logger(subsystem: "com.bivre.bookshelf", category: "Database")

public func createDatabase(id: String, with manager: FileManager) throws -> any DatabaseWriter {
    @Dependency(\.context)
    var context

    var configuration = Configuration()
    #if DEBUG
    configuration.prepareDatabase { db in
        db.trace(options: .profile) {
            if context == .preview {
                          print("\($0.expandedDescription)")
            } else {
                logger.debug("\($0.expandedDescription)")
            }
        }
    }
    #endif

    let fileURL = manager.containerURL(forSecurityApplicationGroupIdentifier: id)!
        .appending(path: "SQLiteData.sqlite")

    let database = try defaultDatabase(path: fileURL.path(), configuration: configuration)

    logger.info("open '\(database.path)'")

    var migrator = DatabaseMigrator()

    #if DEBUG
    migrator.eraseDatabaseOnSchemaChange = true
    #endif

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
