public import Foundation

public import SearchClient

import OSLog
import BookModel

private let logger = Logger(subsystem: "com.bivre.bookshelf", category: "SearchClient")
private let signposter = OSSignposter(logger: logger)

extension SearchClient.By {
    var value: String {
        switch self {
        case let .title(string):
            string
        case let .isbn(string):
            string
        }
    }

    var queryItem: URLQueryItem {
        switch self {
        case let .title(string):
            .init(name: "keyword", value: string)
        case let .isbn(string):
            .init(name: "isbn", value: string)
        }
    }
}

private func createURLRequest(_ by: SearchClient.By) -> URLRequest {
    var component = URLComponents(string: Secret.Backend.baseURL)!
    component.path = "/v1/books/search"
    component.queryItems = [by.queryItem]

    var request = URLRequest(url: component.url!)
    request.setValue(Secret.Backend.apiKey, forHTTPHeaderField: "X-API-Key")
    return request
}

private struct BackendSearchBookResult: Decodable {
    struct Item: Decodable {
        private enum CodingKeys: String, CodingKey {
            case title
            case author
            case price
            case affiliateURL = "affiliateUrl"
            case imageURL = "imageUrl"
            case isbn
            case publisher
            case caption
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
    init(_ item: BackendSearchBookResult.Item) {
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
                    let result = try decoder.decode(BackendSearchBookResult.self, from: data)

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
