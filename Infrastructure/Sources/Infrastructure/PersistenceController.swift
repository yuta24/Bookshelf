public import SwiftData

import CloudKit
import OSLog
import BookRecord

private let logger: Logger = .init(subsystem: "com.bivre.bookshelf", category: "persistence")

func makeSharedStoreURL(_ id: String, with manager: FileManager) -> URL {
    guard let containerURL = manager.containerURL(forSecurityApplicationGroupIdentifier: id) else {
        logger.error("App Group container '\(id)' is unavailable; falling back to the local documents directory")
        let documentsURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first ?? manager.temporaryDirectory
        return documentsURL.appending(path: "Client.sqlite")
    }
    return containerURL.appending(path: "Client.sqlite")
}

public class PersistenceController: @unchecked Sendable {
    enum Constant {
        // swiftlint:disable:next force_cast
        static let appGroupsIdentifier = Bundle.main.object(forInfoDictionaryKey: "AppGroupsName") as! String
        // swiftlint:disable:next force_cast
        static let containerIdentifier = Bundle.main.object(forInfoDictionaryKey: "iCloudContainerName") as! String
    }

    public static let shared: PersistenceController = .init(.default)

    private let manager: FileManager

    public private(set) var container: ModelContainer
    public private(set) var context: ModelContext

    public init(_ manager: FileManager) {
        let configuration = ModelConfiguration(url: makeSharedStoreURL(Constant.appGroupsIdentifier, with: manager), cloudKitDatabase: .none)

        let container: ModelContainer
        do {
            container = try .init(for: BookRecord.self, TagRecord.self, configurations: configuration)
        } catch {
            logger.error("Failed to load persistent store, falling back to an in-memory store: \(error.localizedDescription)")
            // swiftlint:disable:next force_try
            container = try! .init(for: BookRecord.self, TagRecord.self, configurations: .init(isStoredInMemoryOnly: true))
        }

        self.manager = manager

        self.container = container
        self.context = .init(container)
    }

    public func update(with iCloudSync: Bool) throws {
        let container: ModelContainer = try .init(for: BookRecord.self, TagRecord.self, configurations: .init(url: makeSharedStoreURL(Constant.appGroupsIdentifier, with: manager), cloudKitDatabase: iCloudSync ? .automatic : .none))

        self.container = container
        context = .init(container)

        if !iCloudSync {
            let container: CKContainer = .init(identifier: Constant.containerIdentifier)
            container.privateCloudDatabase.delete(withRecordZoneID: .init(zoneName: "com.apple.coredata.cloudkit.zone")) { _, error in
                guard let error else { return }
                logger.error("\(error.localizedDescription)")
            }
        }
    }
}
