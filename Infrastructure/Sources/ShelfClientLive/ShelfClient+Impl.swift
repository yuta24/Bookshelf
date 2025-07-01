public import ShelfClient

public import Infrastructure

import Foundation
import CoreData
import SwiftData
import BookModel
import BookRecord

// swiftlint:disable function_body_length

public extension ShelfClient {
    static func generate(_ controller: PersistenceController) -> Self {
        let calendar = Calendar(identifier: .gregorian)

        return .init(
            create: { item in
                let now = Date()

                let book = Book(
                    id: .init(rawValue: .init()),
                    title: .init(rawValue: item.title),
                    author: .init(rawValue: item.author),
                    price: .init(rawValue: item.price),
                    affiliateURL: item.affiliateURL,
                    imageURL: item.imageURL,
                    isbn: .init(rawValue: item.isbn),
                    publisher: .init(rawValue: item.publisher),
                    caption: item.caption.flatMap(Book.Caption.init(rawValue:)),
                    salesAt: .init(rawValue: item.salesAt),
                    bought: false,
                    note: .init(rawValue: ""),
                    status: .unread,
                    createdAt: now,
                    updatedAt: now,
                    tags: []
                )

                let record = BookRecord()
                record.id = book.id.rawValue
                record.title = book.title.rawValue
                record.author = book.author.rawValue
                record.price = .init(integerLiteral: book.price.rawValue)
                record.affiliateURL = book.affiliateURL
                record.imageURL = book.imageURL
                record.isbn = book.isbn.rawValue
                record.publisher = book.publisher.rawValue
                record.caption = book.caption?.rawValue
                record.salesAt = book.salesAt.rawValue
                record.bought = .init(booleanLiteral: book.bought)
                record.note = book.note.rawValue
                record.status = book.status.string
                record.readAt = book.status.readAt
                record.createdAt = book.createdAt
                record.updatedAt = book.updatedAt

                controller.context.insert(record)
                try controller.context.save()

                return book
            },
            fetchAll: { filter in
                let fetch: FetchDescriptor<BookRecord> = switch filter {
                case let .some(.status(status)):
                    .init(
                        predicate: #Predicate { $0.status.flatMap { $0 == status.string } ?? false },
                        sortBy: [.init(\.createdAt, order: .reverse)]
                    )
                case .none:
                    .init(sortBy: [.init(\.createdAt, order: .reverse)])
                }

                let records = try controller.context.fetch(fetch)

                return records.compactMap(Book.init)
            },
            fetch: { id in
                let fetch: FetchDescriptor<BookRecord> = .init(
                    predicate: #Predicate { $0.id.flatMap { $0 == id.rawValue } ?? false })

                let record = try controller.context.fetch(fetch).first

                return record.flatMap(Book.init)
            },
            update: { book in
                let fetch: FetchDescriptor<BookRecord> = .init(
                    predicate: #Predicate { $0.id.flatMap { $0 == book.id.rawValue } ?? false })

                let record = try controller.context.fetch(fetch).first

                let now = Date()

                record?.imageURL = book.imageURL
                record?.bought = book.bought
                record?.note = book.note.rawValue
                record?.status = book.status.string
                record?.readAt = book.status.readAt
                record?.updatedAt = now
                record?.tags = book.tags.isEmpty ? nil : try {
                    let records: [TagRecord] = try book.tags.map { tag in
                        let fetch: FetchDescriptor<TagRecord> = .init(
                            predicate: #Predicate { $0.id.flatMap { $0 == tag.id.rawValue } ?? false })

                        if let record = try controller.context.fetch(fetch).first {
                            return record
                        } else {
                            let record = TagRecord()
                            record.id = tag.id.rawValue
                            record.name = tag.name
                            record.createdAt = tag.createdAt
                            record.updatedAt = tag.updatedAt
                            return record
                        }
                    }

                    return records
                }()

                try controller.context.save()

                var new = book
                new.updatedAt = now

                return new
            },
            delete: { id in
                try controller.context.delete(
                    model: BookRecord.self,
                    where: #Predicate { $0.id.flatMap { $0 == id.rawValue } ?? false }
                )
                try controller.context.save()
            },
            exists: { isbn in
                let fetch: FetchDescriptor<BookRecord> = .init(
                    predicate: #Predicate<BookRecord> { $0.isbn.flatMap { $0 == isbn.rawValue } ?? false })

                let count = try controller.context.fetchCount(fetch)

                return count > 0
            },
            resume: { books in
                for book in books {
                    let record = BookRecord()
                    record.id = book.id.rawValue
                    record.title = book.title.rawValue
                    record.author = book.author.rawValue
                    record.price = .init(integerLiteral: book.price.rawValue)
                    record.affiliateURL = book.affiliateURL
                    record.imageURL = book.imageURL
                    record.isbn = book.isbn.rawValue
                    record.publisher = book.publisher.rawValue
                    record.caption = book.caption?.rawValue
                    record.salesAt = book.salesAt.rawValue
                    record.bought = .init(booleanLiteral: book.bought)
                    record.note = book.note.rawValue
                    record.status = book.status.string
                    record.readAt = book.status.readAt
                    record.createdAt = book.createdAt
                    record.updatedAt = book.updatedAt

                    controller.context.insert(record)
                }
                try controller.context.save()
            },
            fetchAtYear: { year in
                let startOnYear = calendar.date(from: .init(year: year, month: 1))!
                let startOnNextYear = calendar.date(byAdding: .init(year: 1), to: startOnYear)!

                let fetch: FetchDescriptor<BookRecord> = .init(
                    predicate: #Predicate<BookRecord> {
                        if let createdAt = $0.createdAt {
                            startOnYear <= createdAt && createdAt < startOnNextYear
                        } else {
                            false
                        }
                    },
                    sortBy: [.init(\.updatedAt, order: .reverse)]
                )

                let records = try controller.context.fetch(fetch)

                return records.compactMap(Book.init)
            },
            countAtYear: { year in
                let startOnYear = calendar.date(from: .init(year: year, month: 1))!
                let startOnNextYear = calendar.date(byAdding: .init(year: 1), to: startOnYear)!

                let unreads: Int = try {
                    let fetch: FetchDescriptor<BookRecord> = .init(
                        predicate: #Predicate<BookRecord> { model in
                            if let createdAt = model.createdAt, let status = model.status {
                                startOnYear <= createdAt && createdAt < startOnNextYear && status == "unread"
                            } else {
                                false
                            }
                        })
                    return try controller.context.fetchCount(fetch)
                }()

                let readings: Int = try {
                    let fetch: FetchDescriptor<BookRecord> = .init(
                        predicate: #Predicate<BookRecord> { model in
                            if let createdAt = model.createdAt, let status = model.status {
                                startOnYear <= createdAt && createdAt < startOnNextYear && status == "reading"
                            } else {
                                false
                            }
                        })
                    return try controller.context.fetchCount(fetch)
                }()

                let reads: Int = try {
                    let fetch: FetchDescriptor<BookRecord> = .init(
                        predicate: #Predicate<BookRecord> { model in
                            if let createdAt = model.createdAt, let status = model.status {
                                startOnYear <= createdAt && createdAt < startOnNextYear && status == "read"
                            } else {
                                false
                            }
                        })
                    return try controller.context.fetchCount(fetch)
                }()

                return (unreads, readings, reads)
            }
        )
    }
}

// swiftlint:enable function_body_length
