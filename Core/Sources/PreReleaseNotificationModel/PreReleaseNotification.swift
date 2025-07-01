import Foundation

public import BookModel

public struct PreReleaseNotification: Codable, Equatable, Sendable, Identifiable {
    public let id: UUID
    public let bookId: Book.ID
    public let bookTitle: String
    public let releaseDate: Date
    public let notificationDate: Date
    public let isEnabled: Bool
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        bookId: Book.ID,
        bookTitle: String,
        releaseDate: Date,
        notificationDate: Date,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.bookId = bookId
        self.bookTitle = bookTitle
        self.releaseDate = releaseDate
        self.notificationDate = notificationDate
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

public extension PreReleaseNotification {
    enum NotificationTiming: CaseIterable, Codable, Equatable, Sendable {
        case oneDayBefore
        case threeDaysBefore
        case oneWeekBefore

        public var title: String {
            switch self {
            case .oneDayBefore:
                "1日前"
            case .threeDaysBefore:
                "3日前"
            case .oneWeekBefore:
                "1週間前"
            }
        }

        public var daysBeforeRelease: Int {
            switch self {
            case .oneDayBefore:
                1
            case .threeDaysBefore:
                3
            case .oneWeekBefore:
                7
            }
        }
    }

    static func create(
        for book: Book,
        timing: NotificationTiming
    ) -> PreReleaseNotification? {
        guard let releaseDate = book.salesAt.parsedDate,
              book.canReceivePreReleaseNotification
        else {
            return nil
        }

        let notificationDate = Calendar.current.date(
            byAdding: .day,
            value: -timing.daysBeforeRelease,
            to: releaseDate
        ) ?? releaseDate

        return PreReleaseNotification(
            bookId: book.id,
            bookTitle: book.title.rawValue,
            releaseDate: releaseDate,
            notificationDate: notificationDate
        )
    }

    var isValidForScheduling: Bool {
        isEnabled && notificationDate > Date()
    }

    var notificationIdentifier: String {
        "pre_release_\(bookId.rawValue.uuidString)"
    }
}
