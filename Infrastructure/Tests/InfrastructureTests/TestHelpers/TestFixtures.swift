import Foundation
import BookModel
import BookRecord

/// Test data fixtures for migration testing
public enum TestFixtures {

    // MARK: - BookRecord Fixtures

    /// Create a valid BookRecord with all required fields
    public static func createValidBookRecord(
        id: UUID = UUID(),
        title: String = "Test Book",
        author: String = "Test Author",
        price: Int = 1500,
        affiliateURL: URL? = URL(string: "https://example.com/affiliate"),
        imageURL: URL = URL(string: "https://example.com/image.jpg")!,
        isbn: String = "9784123456789",
        publisher: String = "Test Publisher",
        caption: String? = "Test caption",
        salesAt: String = "2024-01-01",
        bought: Bool = false,
        note: String = "Test note",
        status: String = "unread",
        readAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        tags: [TagRecord] = []
    ) -> BookRecord {
        let record = BookRecord()

        record.affiliateURL = affiliateURL
        record.author = author
        record.bought = bought
        record.caption = caption
        record.createdAt = createdAt
        record.id = id
        record.imageURL = imageURL
        record.isbn = isbn
        record.note = note
        record.price = price
        record.publisher = publisher
        record.readAt = readAt
        record.salesAt = salesAt
        record.status = status
        record.title = title
        record.updatedAt = updatedAt
        record.tags = tags

        return record
    }

    /// Create a BookRecord with missing required fields (for error testing)
    public static func createInvalidBookRecord(
        id: UUID? = nil,
        title: String? = nil,
        author: String? = nil
    ) -> BookRecord {
        let record = BookRecord()

        record.author = author
        record.id = id
        record.title = title

        return record
    }

    /// Create a BookRecord with "read" status
    public static func createReadBookRecord(
        id: UUID = UUID(),
        readAt: Date = Date()
    ) -> BookRecord {
        createValidBookRecord(
            id: id,
            status: "read",
            readAt: readAt
        )
    }

    /// Create a BookRecord with "reading" status
    public static func createReadingBookRecord(
        id: UUID = UUID()
    ) -> BookRecord {
        createValidBookRecord(
            id: id,
            status: "reading"
        )
    }

    // MARK: - TagRecord Fixtures

    /// Create a valid TagRecord
    public static func createValidTagRecord(
        id: UUID = UUID(),
        name: String = "Test Tag",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> TagRecord {
        let record = TagRecord()

        record.id = id
        record.name = name
        record.createdAt = createdAt
        record.updatedAt = updatedAt

        return record
    }

    /// Create an invalid TagRecord (for error testing)
    public static func createInvalidTagRecord(
        id: UUID? = nil,
        name: String? = nil
    ) -> TagRecord {
        let record = TagRecord()

        record.id = id
        record.name = name

        return record
    }

    // MARK: - Book2 Fixtures

    /// Create a valid Book2
    public static func createValidBook2(
        id: UUID = UUID(),
        title: String = "Test Book",
        author: String = "Test Author",
        price: Int = 1500,
        affiliateURL: URL? = URL(string: "https://example.com/affiliate"),
        imageURL: URL = URL(string: "https://example.com/image.jpg")!,
        isbn: String = "9784123456789",
        publisher: String = "Test Publisher",
        caption: String? = "Test caption",
        salesAt: String = "2024-01-01",
        bought: Bool = false,
        note: String = "Test note",
        status: Book2.Status = .unread,
        readAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Book2 {
        Book2(
            id: id,
            title: title,
            author: author,
            price: price,
            affiliateURL: affiliateURL,
            imageURL: imageURL,
            isbn: isbn,
            publisher: publisher,
            caption: caption,
            salesAt: salesAt,
            bought: bought,
            note: note,
            status: status,
            readAt: readAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Tag2 Fixtures

    /// Create a valid Tag2
    public static func createValidTag2(
        id: UUID = UUID(),
        name: String = "Test Tag",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Tag2 {
        Tag2(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Bulk Data Generation

    /// Create multiple BookRecords for bulk testing
    public static func createBookRecords(count: Int) -> [BookRecord] {
        (0..<count).map { index in
            createValidBookRecord(
                id: UUID(),
                title: "Book \(index)",
                author: "Author \(index)",
                isbn: "978412345678\(index % 10)"
            )
        }
    }

    /// Create multiple TagRecords for bulk testing
    public static func createTagRecords(count: Int) -> [TagRecord] {
        (0..<count).map { index in
            createValidTagRecord(
                id: UUID(),
                name: "Tag \(index)"
            )
        }
    }

    /// Create BookRecord with tags
    public static func createBookRecordWithTags(
        bookId: UUID = UUID(),
        tags: [TagRecord]
    ) -> BookRecord {
        createValidBookRecord(
            id: bookId,
            tags: tags
        )
    }
}
