import Foundation
import SQLiteData

@Table("book_tags")
public struct BookTag2: Identifiable, Equatable, Codable, Sendable {
    @Column(primaryKey: true)
    public let id: UUID
    @Column("book_id")
    public let bookId: UUID
    @Column("tag_id")
    public let tagId: UUID

    public init(id: UUID, bookId: UUID, tagId: UUID) {
        self.id = id
        self.bookId = bookId
        self.tagId = tagId
    }
}
