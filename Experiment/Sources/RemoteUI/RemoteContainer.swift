import Foundation
import OSLog

private let logger: Logger = .init(subsystem: "com.bivre.experiment", category: "remote-ui")

public class RemoteContainer: ObservableObject {
    public static let `default`: RemoteContainer = .init()

    @Published
    public private(set) var templates: [RemoteKind: String] = [:]

    public init() {}

    public func setup(directoryURL _: URL) {}
}
