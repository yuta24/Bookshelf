public import Foundation

public import BookClient

import OSLog
import BookModel
import GenreModel

private let logger = Logger(subsystem: "com.bivre.bookshelf", category: "BookClient")
private let signposter = OSSignposter(logger: logger)

extension BookClient.Kind {
    var name: String {
        switch self {
        case .new:
            "new"
        case .sales:
            "sales"
        }
    }
}

private func createURLRequest(_ genre: Genre?, _ kind: BookClient.Kind) -> URLRequest {
    let genreID = if let id = genre?.id {
        id.rawValue
    } else {
        "001"
    }
    let sort = switch kind {
    case .new:
        "-releaseDate"
    case .sales:
        "sales"
    }

    var component = URLComponents(string: Secret.Backend.baseURL)!
    component.path = "/v1/books"
    component.queryItems = [
        .init(name: "genreId", value: genreID),
        .init(name: "sort", value: sort),
    ]

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

public extension BookClient {
    static func generate(_ session: URLSession) -> Self {
        let decoder: JSONDecoder = .init()

        return .init(
            fetch: { genre, kind in
                logger.info("fetch start - \(genre?.id.rawValue ?? "200162")")
                let signpostID = signposter.makeSignpostID()
                let state = signposter.beginInterval("fetch ", id: signpostID, "\(kind.name)")

                defer {
                    logger.info("fetch end")
                    signposter.endInterval("fetch end", state)
                }

                let (data, urlResponse) = try await session.data(for: createURLRequest(genre, kind))

                // swiftlint:disable:next force_cast
                let httpURLResponse = urlResponse as! HTTPURLResponse

                switch httpURLResponse.statusCode {
                case 200 ..< 400:
                    let result = try decoder.decode(BackendSearchBookResult.self, from: data)

                    let json = String(data: data, encoding: .utf8)!
                    logger.info("fetch response - \(json)")

                    return (result.items.map(SearchingBook.init), httpURLResponse)
                default:
                    return ([], httpURLResponse)
                }
            }
        )
    }
}
