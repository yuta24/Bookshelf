import Foundation
import SQLiteData

@Table("tags")
public struct Tag2: Identifiable, Equatable, Codable, Sendable {
    @Column(primaryKey: true)
    public let id: UUID
    public var name: String
    @Column("created_at")
    public let createdAt: Date
    @Column("updated_at")
    public var updatedAt: Date

    public init(id: ID, name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
