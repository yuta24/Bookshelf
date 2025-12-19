import Foundation

/// Convert Book2 and Tag2 (GRDB models) to Book and Tag (domain models)
extension Book {
    /// Create Book from Book2 with tags
    public init(from book2: Book2, tags: [Tag]) {
        // Convert status from Book2.Status to Book.Status
        let status: Book.Status = switch book2.status {
        case .unread:
            .unread
        case .reading:
            .reading
        case .read:
            // If readAt is nil, use current date as fallback
            .read(book2.readAt ?? Date())
        }

        self.init(
            id: .init(rawValue: book2.id),
            title: .init(rawValue: book2.title),
            author: .init(rawValue: book2.author),
            price: .init(rawValue: book2.price),
            affiliateURL: book2.affiliateURL,
            imageURL: book2.imageURL,
            isbn: .init(rawValue: book2.isbn),
            publisher: .init(rawValue: book2.publisher),
            caption: book2.caption.map { .init(rawValue: $0) },
            salesAt: .init(rawValue: book2.salesAt),
            bought: book2.bought,
            note: .init(rawValue: book2.note),
            status: status,
            createdAt: book2.createdAt,
            updatedAt: book2.updatedAt,
            tags: tags.sorted(by: { $0.createdAt < $1.createdAt })
        )
    }
}

extension Tag {
    /// Create Tag from Tag2
    public init(from tag2: Tag2) {
        self.init(
            id: .init(rawValue: tag2.id),
            name: tag2.name,
            createdAt: tag2.createdAt,
            updatedAt: tag2.updatedAt
        )
    }
}
