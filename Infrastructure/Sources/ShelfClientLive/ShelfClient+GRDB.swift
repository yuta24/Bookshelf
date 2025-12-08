public import ShelfClient
public import BookModel

import Foundation
import SQLiteData

// MARK: - GRDB Implementation

public extension ShelfClient {
    static func generateGRDB(_ database: any DatabaseWriter) -> Self {
        let calendar = Calendar(identifier: .gregorian)

        return .init(
            create: { item in
                let now = Date()
                let bookId = UUID()

                let book2 = Book2(
                    id: bookId,
                    title: item.title,
                    author: item.author,
                    price: item.price,
                    affiliateURL: item.affiliateURL,
                    imageURL: item.imageURL,
                    isbn: item.isbn,
                    publisher: item.publisher,
                    caption: item.caption,
                    salesAt: item.salesAt,
                    bought: false,
                    note: "",
                    status: .unread,
                    readAt: nil,
                    createdAt: now,
                    updatedAt: now
                )

                try await database.write { db in
                    try Book2.insert { book2 }.execute(db)
                }

                return Book(from: book2, tags: [])
            },
            fetchAll: { filter in
                try await database.read { db in
                    let books: [Book2]

                    switch filter {
                    case let .some(.status(status)):
                        let targetStatus = status.toBook2Status()
                        books = try Book2
                            .where { $0.status == targetStatus }
                            .order(by: { columns in
                                columns.createdAt.desc()
                            })
                            .fetchAll(db)
                    case .none:
                        books = try Book2
                            .order(by: { columns in
                                columns.createdAt.desc()
                            })
                            .fetchAll(db)
                    }

                    // Fetch tags for each book
                    return try books.map { book2 in
                        let tags = try fetchTagsForBook(book2.id, db: db)
                        return Book(from: book2, tags: tags)
                    }
                }
            },
            fetch: { id in
                try await database.read { db in
                    guard let book2 = try Book2.where({ $0.id == id.rawValue }).fetchOne(db) else {
                        return nil
                    }

                    let tags = try fetchTagsForBook(book2.id, db: db)
                    return Book(from: book2, tags: tags)
                }
            },
            update: { book in
                let now = Date()

                try await database.write { db in
                    // Fetch existing book
                    guard var book2 = try Book2.where({ $0.id == book.id.rawValue }).fetchOne(db) else {
                        throw ShelfClientError.bookNotFound(book.id)
                    }

                    // Update fields
                    book2.imageURL = book.imageURL
                    book2.bought = book.bought
                    book2.note = book.note.rawValue
                    book2.status = book.status.toBook2Status()
                    book2.readAt = book.status.readAt
                    book2.updatedAt = now

                    // Update book
                    try Book2.update(book2).execute(db)

                    // Update tags - delete existing associations and create new ones
                    try BookTag2.where { $0.bookId == book2.id }.delete().execute(db)

                    for tag in book.tags {
                        // Ensure tag exists or create it
                        let tag2: Tag2
                        if let existing = try Tag2.where({ $0.id == tag.id.rawValue }).fetchOne(db) {
                            tag2 = existing
                        } else {
                            tag2 = Tag2(
                                id: tag.id.rawValue,
                                name: tag.name,
                                createdAt: tag.createdAt,
                                updatedAt: tag.updatedAt
                            )
                            try Tag2.insert { tag2 }.execute(db)
                        }

                        // Create association
                        try #sql("""
                        INSERT INTO book_tags (book_id, tag_id) VALUES (
                        \(book2.id), \(tag2.id)
                        )
                        """).execute(db)
                    }
                }

                var updated = book
                updated.updatedAt = now
                return updated
            },
            delete: { id in
                try await database.write { db in
                    try Book2.where { $0.id == id.rawValue }.delete().execute(db)
                }
            },
            exists: { isbn in
                try await database.read { db in
                    let count = try Book2.where { $0.isbn == isbn.rawValue }.fetchCount(db)
                    return count > 0
                }
            },
            resume: { books in
                try await database.write { db in
                    for book in books {
                        let book2 = Book2(
                            id: book.id.rawValue,
                            title: book.title.rawValue,
                            author: book.author.rawValue,
                            price: book.price.rawValue,
                            affiliateURL: book.affiliateURL,
                            imageURL: book.imageURL,
                            isbn: book.isbn.rawValue,
                            publisher: book.publisher.rawValue,
                            caption: book.caption?.rawValue,
                            salesAt: book.salesAt.rawValue,
                            bought: book.bought,
                            note: book.note.rawValue,
                            status: book.status.toBook2Status(),
                            readAt: book.status.readAt,
                            createdAt: book.createdAt,
                            updatedAt: book.updatedAt
                        )

                        try Book2.insert { book2 }.execute(db)

                        // Insert tags and associations
                        for tag in book.tags {
                            // Ensure tag exists
                            if try Tag2.where({ $0.id == tag.id.rawValue }).fetchOne(db) == nil {
                                let tag2 = Tag2(
                                    id: tag.id.rawValue,
                                    name: tag.name,
                                    createdAt: tag.createdAt,
                                    updatedAt: tag.updatedAt
                                )
                                try Tag2.insert { tag2 }.execute(db)
                            }

                            let bookTag = BookTag2(id: .init(), bookId: book2.id, tagId: tag.id.rawValue)

                            // Create association
                            try BookTag2.insert { bookTag }.execute(db)
                        }
                    }
                }
            },
            fetchAtYear: { year in
                try await database.read { db in
                    let startOfYear = calendar.date(from: .init(year: year, month: 1))!
                    let startOfNextYear = calendar.date(byAdding: .init(year: 1), to: startOfYear)!

                    let books = try Book2
                        .where { $0.createdAt >= startOfYear && $0.createdAt < startOfNextYear }
                        .order(by: { columns in
                            columns.updatedAt.desc()
                        })
                        .fetchAll(db)

                    return try books.map { book2 in
                        let tags = try fetchTagsForBook(book2.id, db: db)
                        return Book(from: book2, tags: tags)
                    }
                }
            },
            countAtYear: { year in
                try await database.read { db in
                    let startOfYear = calendar.date(from: .init(year: year, month: 1))!
                    let startOfNextYear = calendar.date(byAdding: .init(year: 1), to: startOfYear)!

                    let unreadCount = try #sql(
                        """
                        SELECT count(*)
                        FROM \(Book2.self)
                        WHERE \(startOfYear) <= \(Book2.createdAt)
                            AND \(Book2.createdAt) < \(startOfNextYear)
                            AND \(Book2.status) == "unread"
                        """,
                        as: Int.self).fetchOne(db) ?? 0

                    let readingCount = try #sql(
                        """
                        SELECT count(*)
                        FROM \(Book2.self)
                        WHERE \(startOfYear) <= \(Book2.createdAt)
                            AND \(Book2.createdAt) < \(startOfNextYear)
                            AND \(Book2.status) == "reading"
                        """,
                        as: Int.self).fetchOne(db) ?? 0

                    let readCount = try #sql(
                        """
                        SELECT count(*)
                        FROM \(Book2.self)
                        WHERE \(startOfYear) <= \(Book2.createdAt)
                            AND \(Book2.createdAt) < \(startOfNextYear)
                            AND \(Book2.status) == "read"
                        """,
                        as: Int.self).fetchOne(db) ?? 0

                    return (unreadCount, readingCount, readCount)
                }
            }
        )
    }
}

// MARK: - Helper Functions

private func fetchTagsForBook(_ bookId: UUID, db: Database) throws -> [Tag] {
    // Get tag IDs from join table
    let bookTags = try BookTag2.where { $0.bookId == bookId }.order(by: \.tagId).fetchAll(db)

    // Fetch tags
    let tag2s = try bookTags.compactMap { bookTag in
        try Tag2.where { $0.id == bookTag.tagId }.fetchOne(db)
    }

    return tag2s.map(Tag.init)
}

// MARK: - Status Conversion Extension

private extension Book.Status {
    func toBook2Status() -> Book2.Status {
        switch self {
        case .unread:
            return .unread
        case .reading:
            return .reading
        case .read:
            return .read
        }
    }
}

// MARK: - Error Types

public enum ShelfClientError: Error {
    case bookNotFound(Book.ID)
}
