import Foundation
import SwiftData
import BookRecord

/// Test version of PersistenceController that uses in-memory storage
public final class TestPersistenceController: @unchecked Sendable {
    public private(set) var container: ModelContainer
    public private(set) var context: ModelContext

    /// Create a new in-memory test persistence controller
    public init() {
        // Create in-memory model configuration
        let schema = Schema([BookRecord.self, TagRecord.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )

        do {
            self.container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
            self.context = ModelContext(container)
        } catch {
            fatalError("Failed to create test ModelContainer: \(error)")
        }
    }

    /// Insert test data and save context
    public func insert(_ records: [BookRecord]) throws {
        for record in records {
            context.insert(record)
        }
        try context.save()
    }

    /// Insert test data and save context
    public func insert(_ records: [TagRecord]) throws {
        for record in records {
            context.insert(record)
        }
        try context.save()
    }

    /// Fetch all BookRecords
    public func fetchAllBooks() throws -> [BookRecord] {
        let descriptor = FetchDescriptor<BookRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Fetch all TagRecords
    public func fetchAllTags() throws -> [TagRecord] {
        let descriptor = FetchDescriptor<TagRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    /// Clear all data from context
    public func clearAll() throws {
        // Delete all books
        let books = try fetchAllBooks()
        for book in books {
            context.delete(book)
        }

        // Delete all tags
        let tags = try fetchAllTags()
        for tag in tags {
            context.delete(tag)
        }

        try context.save()
    }

    /// Count records in context
    public func countBooks() throws -> Int {
        try fetchAllBooks().count
    }

    /// Count records in context
    public func countTags() throws -> Int {
        try fetchAllTags().count
    }
}

// MARK: - Convenience Extensions

extension TestPersistenceController {
    /// Create a test controller with pre-populated data
    public static func withData(
        books: [BookRecord] = [],
        tags: [TagRecord] = []
    ) throws -> TestPersistenceController {
        let controller = TestPersistenceController()
        try controller.insert(tags)
        try controller.insert(books)
        return controller
    }
}
