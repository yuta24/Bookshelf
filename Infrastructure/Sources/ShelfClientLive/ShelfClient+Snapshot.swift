public import ShelfClient

public import Infrastructure

import BookRecord
import Foundation
import SwiftData
import BookModel

private extension CodingUserInfoKey {
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")!
}

// swiftlint:disable all

public extension ShelfClient {
    static func snapshot(_: PersistenceController) -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let url = Bundle.main.url(forResource: "Records", withExtension: "json")!
        let data = try! Data(contentsOf: url)
        let records = try! decoder.decode([BookRecord].self, from: data)
        let books = records.compactMap { Book($0) }

        let calendar = Calendar(identifier: .gregorian)

        return .init(
            create: { _ in
                fatalError()
            },
            fetchAll: { _ in
                let url = Bundle.main.url(forResource: "Records", withExtension: "json")!
                let data = try! Data(contentsOf: url)
                let records = try! decoder.decode([BookRecord].self, from: data)
                return records.compactMap { Book($0) }.sorted(by: { $0.createdAt > $1.createdAt })
            },
            fetch: { _ in
                fatalError()
            },
            update: { _ in
                fatalError()
            },
            delete: { _ in
                fatalError()
            },
            exists: { _ in
                fatalError()
            },
            resume: { _ in
                fatalError()
            },
            fetchAtYear: { year in
                let startOnYear = calendar.date(from: .init(year: year, month: 1))!
                let startOnNextYear = calendar.date(byAdding: .init(year: 1), to: startOnYear)!
                return books.filter { startOnYear <= $0.createdAt && $0.createdAt < startOnNextYear }
            },
            countAtYear: { _ in
                (0, 0, 0)
            }
        )
    }
}

// swiftlint:enable all
