public import Foundation

public import Tagged

public struct Book: Identifiable, Equatable, Codable, Sendable {
    public typealias ID = Tagged<(Book, id: ()), UUID>
    public typealias Title = Tagged<(Book, title: ()), String>
    public typealias Author = Tagged<(Book, author: ()), String>
    public typealias Price = Tagged<(Book, price: ()), Int>
    public typealias ISBN = Tagged<(Book, isbn: ()), String>
    public typealias Publisher = Tagged<(Book, publisher: ()), String>
    public typealias Caption = Tagged<(Book, caption: ()), String>
    public typealias SalesAt = Tagged<(Book, salesAt: ()), String>
    public typealias Note = Tagged<(Book, note: ()), String>

    public enum Status: Equatable, Codable, Sendable {
        case unread
        case reading
        case read(Date)
    }

    public let id: ID
    public let title: Title
    public let author: Author
    public let price: Price
    public let affiliateURL: URL?
    public var imageURL: URL
    public let isbn: ISBN
    public let publisher: Publisher
    public let caption: Caption?
    public let salesAt: SalesAt
    public var bought: Bool
    public var note: Note
    public var status: Status
    public let createdAt: Date
    public var updatedAt: Date
    public var tags: [Tag]

    public init(
        id: ID,
        title: Title,
        author: Author,
        price: Price,
        affiliateURL: URL?,
        imageURL: URL,
        isbn: ISBN,
        publisher: Publisher,
        caption: Caption?,
        salesAt: SalesAt,
        bought: Bool,
        note: Note,
        status: Status,
        createdAt: Date,
        updatedAt: Date,
        tags: [Tag]
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
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.tags = tags
    }
}

public extension Book.Status {
    var string: String {
        switch self {
        case .unread:
            "unread"
        case .reading:
            "reading"
        case .read:
            "read"
        }
    }

    var readAt: Date? {
        switch self {
        case .unread:
            nil
        case .reading:
            nil
        case let .read(date):
            date
        }
    }
}

public extension Book.SalesAt {
    var parsedDate: Date? {
        let dateString = rawValue
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        if dateString.contains("年"), dateString.contains("月"), dateString.contains("日") {
            let cleanString = dateString
                .replacingOccurrences(of: "頃", with: "")
                .trimmingCharacters(in: .whitespaces)
            formatter.dateFormat = "yyyy年MM月dd日"
            return formatter.date(from: cleanString)
        } else if dateString.contains("年"), dateString.contains("月") {
            let cleanString = dateString
                .replacingOccurrences(of: "頃", with: "")
                .trimmingCharacters(in: .whitespaces)
            formatter.dateFormat = "yyyy年MM月"
            return formatter.date(from: cleanString)
        } else if dateString.matches("\\d{4}-\\d{2}-\\d{2}") {
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.date(from: dateString)
        }

        return nil
    }

    var isPreRelease: Bool {
        guard let releaseDate = parsedDate else { return false }
        return releaseDate > Date()
    }

    var hasPassedReleaseDate: Bool {
        !isPreRelease
    }
}

public extension Book {
    var canReceivePreReleaseNotification: Bool {
        salesAt.isPreRelease
    }
}

private extension String {
    func matches(_ pattern: String) -> Bool {
        range(of: pattern, options: .regularExpression) != nil
    }
}

public extension Book.ISBN {
    func convertTo10() -> Book.ISBN? {
        var values = rawValue.replacingOccurrences(of: "-", with: "")
            .compactMap { Int("\($0)") }

        guard values.count == 13 else { return nil }

        values.removeFirst(3)
        values.removeLast()

        let digit = 11 - values.enumerated().reduce(into: 0) { partialResult, value in
            partialResult += (10 - value.offset) * value.element
        } % 11

        let check = switch digit {
        case 10:
            "X"
        case 11:
            "0"
        default:
            "\(digit)"
        }

        return .init(rawValue: "\(values.map { "\($0)" }.joined())\(check)")
    }
}
