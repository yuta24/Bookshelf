import Foundation
import KZFileWatchers
import OSLog

private let logger: Logger = .init(subsystem: "com.bivre.experiment", category: "hot-component")

public class ComponentContainer: ObservableObject {
    public static let `default`: ComponentContainer = .init()

    public let registry: ComponentRegistry = .init()

    @Published
    public var payloads: [AnyHashable: any Decodable] = [:]

    private var watcher: FileWatcherProtocol?

    public init() {}

    public func load(with url: URL) {
        let data = try! Data(contentsOf: url)
        parse(data)
    }

    public func observe(with url: URL) {
        logger.debug("Component file is observing: \(url.absoluteString)")

        watcher = FileWatcher.Local(path: url.absoluteString)
        try! watcher?.start { [weak self] result in
            logger.debug("Component file changed")
            switch result {
            case .noChanges:
                break
            case let .updated(data: data):
                self?.parse(data)
            }
        }
    }

    func parse(_ data: Data) {
        do {
            payloads = try registry.decode(from: data)
        } catch {
            logger.debug("\(error.localizedDescription)")
        }
    }
}
