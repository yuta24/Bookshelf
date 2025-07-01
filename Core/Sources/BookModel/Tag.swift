public import Foundation

public import Tagged

public struct Tag: Identifiable, Equatable, Codable, Sendable {
    public typealias ID = Tagged<(Tag, id: ()), UUID>

    public let id: ID
    public var name: String
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: ID, name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
