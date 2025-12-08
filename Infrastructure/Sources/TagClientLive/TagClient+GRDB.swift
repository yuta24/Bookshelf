public import TagClient
public import BookModel

import Foundation
import SQLiteData

// MARK: - GRDB Implementation

public extension TagClient {
    static func generateGRDB(_ database: any DatabaseWriter) -> Self {
        .init(
            create: { item in
                let now = Date()
                let tagId = UUID()

                let tag2 = Tag2(
                    id: tagId,
                    name: item.name,
                    createdAt: now,
                    updatedAt: now
                )

                try await database.write { db in
                    try Tag2.insert { tag2 }.execute(db)
                }

                return Tag(from: tag2)
            },
            fetchAll: {
                try await database.read { db in
                    let tags = try Tag2
                        .order(by: \.name)
                        .fetchAll(db)

                    return tags.map(Tag.init(from:))
                }
            },
            update: { tag in
                let now = Date()

                try await database.write { db in
                    // Verify tag exists first
                    guard try Tag2.where({ $0.id == tag.id.rawValue }).fetchOne(db) != nil else {
                        throw TagClientError.tagNotFound(tag.id)
                    }

                    // Update tag using raw SQL with string interpolation for UUID
                    try db.execute(
                        sql: "UPDATE tags SET name = ?, updated_at = ? WHERE id = '\(tag.id.rawValue.uuidString)'",
                        arguments: [tag.name, now]
                    )
                }

                var updated = tag
                updated.updatedAt = now
                return updated
            },
            delete: { id in
                try await database.write { db in
                    try db.execute(
                        sql: "DELETE FROM tags WHERE id = '\(id.rawValue.uuidString)'"
                    )
                }
            },
            exists: { name in
                try await database.read { db in
                    let count = try Tag2.where { $0.name == name }.fetchCount(db)
                    return count > 0
                }
            }
        )
    }
}

// MARK: - Error Types

public enum TagClientError: Error {
    case tagNotFound(Tag.ID)
}
