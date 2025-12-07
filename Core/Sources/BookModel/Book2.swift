public import Foundation

import SQLiteData
import Tagged

@Table("books")
public struct Book2: Identifiable, Hashable, Codable, Sendable {
    public enum Status: String, QueryBindable, Hashable, Codable, Sendable {
        case unread
        case reading
        case read
    }

    @Column(primaryKey: true)
    public let id: UUID
    public let title: String
    public let author: String
    public let price: Int
    @Column("affiliate_url")
    public let affiliateURL: URL?
    @Column("image_url")
    public var imageURL: URL
    public let isbn: String
    public let publisher: String
    public let caption: String?
    @Column("sales_at")
    public let salesAt: String
    public var bought: Bool
    public var note: String
    public var status: Status
    @Column("read_at")
    public var readAt: Date?
    @Column("created_at")
    public let createdAt: Date
    @Column("updated_at")
    public var updatedAt: Date

    public init(
        id: UUID,
        title: String,
        author: String,
        price: Int,
        affiliateURL: URL?,
        imageURL: URL,
        isbn: String,
        publisher: String,
        caption: String?,
        salesAt: String,
        bought: Bool,
        note: String,
        status: Status,
        readAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.price = price
        self.affiliateURL = affiliateURL
        self.imageURL = imageURL
        self.isbn = isbn
        self.publisher = publisher
        self.caption = caption
        self.salesAt = salesAt
        self.bought = bought
        self.note = note
        self.status = status
        self.readAt = readAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
