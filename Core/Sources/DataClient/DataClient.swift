public import Dependencies
public import BookModel

import Foundation
import DependenciesMacros

@DependencyClient
public struct DataClient: Sendable {
    public var export: @Sendable () async throws -> Data
    public var `import`: @Sendable (Data) async throws -> ImportResult
}

public struct ImportResult: Sendable, Equatable {
    public let importedBooksCount: Int
    public let importedTagsCount: Int

    public init(importedBooksCount: Int, importedTagsCount: Int) {
        self.importedBooksCount = importedBooksCount
        self.importedTagsCount = importedTagsCount
    }
}

public struct ExportData: Codable, Equatable, Sendable {
    public let version: Int
    public let exportedAt: Date
    public let books: [Book]
    public let tags: [Tag]

    public init(books: [Book], tags: [Tag]) {
        self.version = 1
        self.exportedAt = Date()
        self.books = books
        self.tags = tags
    }
}

public enum DataExportError: LocalizedError, Sendable, Equatable {
    case invalidVersion
    case invalidData
    case importFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidVersion: "Invalid export version"
        case .invalidData: "Invalid export data format"
        case let .importFailed(message): "Import failed: \(message)"
        }
    }
}

extension DataClient: DependencyKey {
    public static let liveValue: DataClient = .init()
}
