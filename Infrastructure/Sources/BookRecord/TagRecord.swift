public import Foundation
public import SwiftData

public import BookModel

@Model
public final class TagRecord: Decodable {
    public var createdAt: Date?
    public var id: UUID?
    public var name: String?
    public var updatedAt: Date?
    public var books: [BookRecord]?

    public init() {}

    public enum CodingKeys: CodingKey {
        case id
        case name
        case createdAt
        case updatedAt
        case books
    }

    public required convenience init(from decoder: any Decoder) throws {
        self.init()

        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }
}

public extension Tag {
    init?(_ record: TagRecord) {
        guard let id = record.id else { return nil }
        guard let name = record.name else { return nil }
        guard let createdAt = record.createdAt else { return nil }
        guard let updatedAt = record.updatedAt else { return nil }

        self.init(
            id: .init(rawValue: id),
            name: name,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
