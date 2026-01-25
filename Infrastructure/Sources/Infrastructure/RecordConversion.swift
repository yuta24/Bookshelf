import Foundation
import BookModel
import BookRecord

/// Errors that can occur during record conversion
public enum RecordConversionError: Error {
    case missingRequiredField(String)
    case invalidStatusValue(String?)

    public var localizedDescription: String {
        switch self {
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidStatusValue(let value):
            return "Invalid status value: \(value ?? "nil")"
        }
    }
}

/// Utilities for converting SwiftData records to GRDB models
public struct RecordConversion {

    /// Convert BookRecord to Book2
    public static func convertToBook2(_ record: BookRecord) throws -> Book2 {
        // Validate and unwrap required fields
        guard let id = record.id else {
            throw RecordConversionError.missingRequiredField("id")
        }
        guard let title = record.title else {
            throw RecordConversionError.missingRequiredField("title")
        }
        guard let author = record.author else {
            throw RecordConversionError.missingRequiredField("author")
        }
        guard let price = record.price else {
            throw RecordConversionError.missingRequiredField("price")
        }
        guard let imageURL = record.imageURL else {
            throw RecordConversionError.missingRequiredField("imageURL")
        }
        guard let isbn = record.isbn else {
            throw RecordConversionError.missingRequiredField("isbn")
        }
        guard let publisher = record.publisher else {
            throw RecordConversionError.missingRequiredField("publisher")
        }
        guard let salesAt = record.salesAt else {
            throw RecordConversionError.missingRequiredField("salesAt")
        }
        guard let createdAt = record.createdAt else {
            throw RecordConversionError.missingRequiredField("createdAt")
        }
        guard let updatedAt = record.updatedAt else {
            throw RecordConversionError.missingRequiredField("updatedAt")
        }

        // Convert status from String to enum
        let status: Book2.Status = switch record.status {
        case "unread":
            .unread
        case "reading":
            .reading
        case "read":
            .read
        case .none:
            .unread  // Default to unread if status is nil
        default:
            throw RecordConversionError.invalidStatusValue(record.status)
        }

        // Create Book2 instance
        return Book2(
            id: id,
            title: title,
            author: author,
            price: price,
            affiliateURL: record.affiliateURL,
            imageURL: imageURL,
            isbn: isbn,
            publisher: publisher,
            caption: record.caption,
            salesAt: salesAt,
            bought: record.bought ?? false,
            note: record.note ?? "",
            status: status,
            readAt: record.readAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Convert TagRecord to Tag2
    public static func convertToTag2(_ record: TagRecord) throws -> Tag2 {
        // Validate and unwrap required fields
        guard let id = record.id else {
            throw RecordConversionError.missingRequiredField("id")
        }
        guard let name = record.name else {
            throw RecordConversionError.missingRequiredField("name")
        }
        guard let createdAt = record.createdAt else {
            throw RecordConversionError.missingRequiredField("createdAt")
        }
        guard let updatedAt = record.updatedAt else {
            throw RecordConversionError.missingRequiredField("updatedAt")
        }

        // Create Tag2 instance
        return Tag2(
            id: id,
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Extract book-tag associations from BookRecord
    /// Returns a dictionary mapping book IDs to arrays of tag IDs
    public static func extractBookTagAssociations(_ books: [BookRecord]) -> [UUID: [UUID]] {
        var associations: [UUID: [UUID]] = [:]

        for book in books {
            guard let bookId = book.id else { continue }

            let tagIds = book.tags?
                .compactMap { $0.id } ?? []

            if !tagIds.isEmpty {
                associations[bookId] = tagIds
            }
        }

        return associations
    }
}
