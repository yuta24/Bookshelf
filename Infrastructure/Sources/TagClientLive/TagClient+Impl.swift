public import TagClient

public import Infrastructure

import Foundation
import SwiftData
import BookModel
import BookRecord

public extension TagClient {
    static func generate(_ controller: PersistenceController) -> TagClient {
        .init(
            create: { item in
                let now = Date()

                let tag = Tag(
                    id: .init(rawValue: .init()),
                    name: item.name,
                    createdAt: now,
                    updatedAt: now
                )

                let record = TagRecord()
                record.id = tag.id.rawValue
                record.name = tag.name
                record.createdAt = tag.createdAt
                record.updatedAt = tag.updatedAt

                controller.context.insert(record)
                try controller.context.save()

                return tag
            },
            fetchAll: {
                let fetch: FetchDescriptor<TagRecord> = .init(sortBy: [.init(\.name, order: .forward)])

                let records = try controller.context.fetch(fetch)

                return records.compactMap(Tag.init)
            },
            update: { tag in
                let fetch: FetchDescriptor<TagRecord> = .init(
                    predicate: #Predicate<TagRecord> { $0.id.flatMap { $0 == tag.id.rawValue } ?? false })

                let now = Date()

                let record = try controller.context.fetch(fetch).first
                record?.name = tag.name

                try controller.context.save()

                var new = tag
                new.updatedAt = now

                return new
            },
            delete: { id in
                try controller.context.delete(
                    model: TagRecord.self,
                    where: #Predicate<TagRecord> { $0.id.flatMap { $0 == id.rawValue } ?? false }
                )
                try controller.context.save()
            },
            exists: { name in
                let fetch: FetchDescriptor<TagRecord> = .init(
                    predicate: #Predicate<TagRecord> { $0.name == name })

                let count = try controller.context.fetchCount(fetch)

                return count > 0
            }
        )
    }
}

extension Tag {
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
