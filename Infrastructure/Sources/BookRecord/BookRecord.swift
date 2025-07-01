public import Foundation

public import SwiftData

public import BookModel

@Model
public final class BookRecord: Decodable {
    public var affiliateURL: URL?
    public var author: String?
    public var bought: Bool?
    public var caption: String?
    public var createdAt: Date?
    public var id: UUID?
    public var imageURL: URL?
    public var isbn: String?
    public var note: String?
    public var price: Int?
    public var publisher: String?
    public var readAt: Date?
    public var salesAt: String?
    public var status: String?
    public var title: String?
    public var updatedAt: Date?

    @Relationship(inverse: \TagRecord.books)
    public var tags: [TagRecord]?

    public init() {}

    public enum CodingKeys: CodingKey {
        case id
        case title
        case author
        case price
        case affiliateURL
        case imageURL
        case isbn
        case publisher
        case caption
        case salesAt
        case bought
        case note
        case status
        case readAt
        case createdAt
        case updatedAt
        case tags
    }

    public required convenience init(from decoder: any Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.price = try container.decodeIfPresent(Int.self, forKey: .price)
        self.affiliateURL = try container.decodeIfPresent(URL.self, forKey: .affiliateURL)
        self.imageURL = try container.decodeIfPresent(URL.self, forKey: .imageURL)
        self.isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.caption = try container.decodeIfPresent(String.self, forKey: .caption)
        self.salesAt = try container.decodeIfPresent(String.self, forKey: .salesAt)
        self.bought = try container.decodeIfPresent(Bool.self, forKey: .bought)
        self.note = try container.decodeIfPresent(String.self, forKey: .note)
        self.status = try container.decodeIfPresent(String.self, forKey: .status)
        self.readAt = try container.decodeIfPresent(Date.self, forKey: .readAt)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public extension Book {
    init?(_ record: BookRecord) {
        guard let id = record.id else { return nil }
        guard let title = record.title else { return nil }
        guard let author = record.author else { return nil }
        guard let price = record.price else { return nil }
        guard let imageURL = record.imageURL else { return nil }
        guard let isbn = record.isbn else { return nil }
        guard let publisher = record.publisher else { return nil }
        guard let salesAt = record.salesAt else { return nil }
        guard let createdAt = record.createdAt else { return nil }
        guard let updatedAt = record.updatedAt else { return nil }

        let status: Book.Status = {
            switch record.status {
            case "unread":
                .unread
            case "reading":
                .reading
            case "read":
                if let readAt = record.readAt {
                    .read(readAt)
                } else {
                    nil
                }
            default:
                nil
            }
        }() ?? .unread

        let tags = record.tags?
            .compactMap { Tag($0) } ?? []

        self.init(
            id: .init(rawValue: id),
            title: .init(rawValue: title),
            author: .init(rawValue: author),
            price: .init(rawValue: price),
            affiliateURL: record.affiliateURL,
            imageURL: imageURL,
            isbn: .init(rawValue: isbn),
            publisher: .init(rawValue: publisher),
            caption: record.caption.flatMap(Book.Caption.init(rawValue:)),
            salesAt: .init(rawValue: salesAt),
            bought: record.bought ?? false,
            note: record.note.flatMap(Book.Note.init(rawValue:)) ?? .init(rawValue: ""),
            status: status,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: tags.sorted(by: { $0.createdAt < $1.createdAt })
        )
    }
}
