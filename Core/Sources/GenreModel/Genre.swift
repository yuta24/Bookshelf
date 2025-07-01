public import Tagged

import Foundation

public struct Genre: Identifiable, Hashable, Codable, Sendable {
    public typealias ID = Tagged<(Genre, id: ()), String>

    enum CodingKeys: String, CodingKey {
        case id = "booksGenreId"
        case name = "booksGenreName"
    }

    public let id: ID
    public let name: String

    public init(id: ID, name: String) {
        self.id = id
        self.name = name
    }
}
