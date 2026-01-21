public import Dependencies

import Foundation
import DependenciesMacros

@DependencyClient
public struct DataClient: Sendable {
    public var export: @Sendable () async throws -> String?
    public var `import`: @Sendable (Data) async throws -> Void
}

public enum DataError: LocalizedError, Sendable, Equatable {
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
