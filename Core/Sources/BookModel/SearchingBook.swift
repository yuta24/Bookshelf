public import Foundation

public struct SearchingBook: Identifiable, Equatable, Sendable {
    public let title: String
    public let author: String
    public let price: Int
    public let affiliateURL: URL?
    public let imageURL: URL
    public let isbn: String
    public let publisher: String
    public let caption: String?
    public let salesAt: String
    public var registered: Bool?

    public var id: String {
        isbn
    }

    public init(
        title: String,
        author: String,
        price: Int,
        affiliateURL: URL?,
        imageURL: URL,
        isbn: String,
        publisher: String,
        caption: String?,
        salesAt: String,
        registered: Bool?
    ) {
        self.title = title
        self.author = author
        self.price = price
        self.affiliateURL = affiliateURL
        self.imageURL = imageURL
        self.isbn = isbn
        self.publisher = publisher
        self.caption = caption
        self.salesAt = salesAt
        self.registered = registered
    }
}
