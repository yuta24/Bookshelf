public import Foundation

public import SearchClient

import OSLog
import BookModel

private let logger = Logger(subsystem: "com.bivre.bookshelf", category: "SearchClient")
private let signposter = OSSignposter(logger: logger)

extension SearchClient.By {
    var name: String {
        switch self {
        case .title:
            "title"
        case .isbn:
            "isbn"
        }
    }

    var value: String {
        switch self {
        case let .title(string):
            string
        case let .isbn(string):
            string
        }
    }
}

private func createURLRequest(_ by: SearchClient.By) -> URLRequest {
    var component = URLComponents()
    component.scheme = "https"
    component.host = "app.rakuten.co.jp"
    component.path = "/services/api/BooksTotal/Search/20170404"
    component.queryItems = [
        .init(name: "applicationId", value: Secret.Rakuten.applicationId),
        .init(name: "affiliateId", value: Secret.Rakuten.affiliateId),
        .init(name: "format", value: "json"),
        .init(name: "formatVersion", value: "2"),
        .init(name: "keyword", value: by.value),
        .init(name: "booksGenreId", value: "001"),
        .init(name: "outOfStockFlag", value: "1"),
    ]

    return URLRequest(url: component.url!)
}

private struct RakutenSearchBookResult: Decodable {
    private enum CodingKeys: String, CodingKey {
        case items = "Items"
    }

    struct Item: Decodable {
        private enum CodingKeys: String, CodingKey {
            case title
            case author
            case price = "itemPrice"
            case affiliateURL = "affiliateUrl"
            case imageURL = "largeImageUrl"
            case isbn
            case publisher = "publisherName"
            case caption = "itemCaption"
            case salesAt = "salesDate"
        }

        let title: String
        let author: String
        let price: Int
        let affiliateURL: URL?
        let imageURL: URL
        let isbn: String
        let publisher: String
        let caption: String?
        let salesAt: String
    }

    let items: [Item]
}

private extension SearchingBook {
    init(_ item: RakutenSearchBookResult.Item) {
        self.init(
            title: item.title,
            author: item.author,
            price: item.price,
            affiliateURL: item.affiliateURL,
            imageURL: item.imageURL,
            isbn: item.isbn,
            publisher: item.publisher,
            caption: item.caption,
            salesAt: item.salesAt,
            registered: nil
        )
    }
}

public extension SearchClient {
    static func generate(_ session: URLSession) -> SearchClient {
        let decoder: JSONDecoder = .init()

        return .init(
            search: { by in
                logger.info("search start - \(by.value)")
                let signpostID = signposter.makeSignpostID()
                let state = signposter.beginInterval("search start", id: signpostID, "\(by.value)")

                defer {
                    logger.info("search end")
                    signposter.endInterval("search end", state)
                }

                let (data, urlResponse) = try await session.data(for: createURLRequest(by))

                // swiftlint:disable:next force_cast
                let httpURLResponse = urlResponse as! HTTPURLResponse

                switch httpURLResponse.statusCode {
                case 200 ..< 400:
                    let result = try decoder.decode(RakutenSearchBookResult.self, from: data)

                    let json = String(data: data, encoding: .utf8)!
                    logger.info("search response - \(json)")

                    return (result.items.map(SearchingBook.init), httpURLResponse)
                default:
                    return ([], httpURLResponse)
                }
            }
        )
    }
}
