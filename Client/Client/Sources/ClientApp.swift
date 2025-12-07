import SwiftUI
import ComposableArchitecture
import Presentation
import System
import Infrastructure
import AnalyticsClientLive
import BookClientLive
import GenreClientLive
import PreReleaseNotificationClientLive
import RemindClientLive
import SearchClientLive
import ShelfClientLive
import SyncClient
import SyncClientLive
import TagClientLive
import MigrationCore
import BookModel
import SQLiteData

// swiftlint:disable force_try force_cast

@main
struct ClientApp: App {
    let appGroupsName: String

    // Use GRDB clients by default
    let isSnapshot: Bool

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var delegate

    var body: some Scene {
        WindowGroup {
            let database = try! createDatabase(id: appGroupsName, with: .default)

            // Create migration client
            let migrationClient = MigrationClient.generate(
                persistence: delegate.persistence,
                grdbDatabase: database
            )

            let syncEngine = try! SyncEngine(for: database, tables: Book2.self, Tag2.self, BookTag2.self)

            // Check if migration is completed
            let isMigrationCompleted = migrationClient.isCompleted()

            RootBuilder.build(
                gateway: .init(
                    analyticsClient: .generate(),
                    bookClient: .generate(.shared),
                    database: database,
                    genreClient: .generate(.remoteConfig()),
                    preReleaseNotificationClient: .generate(),
                    remindClient: .generate(),
                    searchClient: .generate(.shared),
                    shelfClient: {
                        if isSnapshot {
                            return .snapshot(delegate.persistence)
                        } else if isMigrationCompleted {
                            // After migration: use GRDB
                            return .generateGRDB(database)
                        } else {
                            // Before migration: use SwiftData
                            return .generate(delegate.persistence)
                        }
                    }(),
                    syncClient: {
                        let repository = SyncClient.generate { enabled in
                            try! delegate.persistence.update(with: enabled)
                        }
                        try! delegate.persistence.update(with: repository.fetch()?.enabled ?? false)
                        return repository
                    }(),
                    syncEngine: syncEngine,
                    tagClient: isMigrationCompleted
                        ? .generateGRDB(database)  // After migration: use GRDB
                        : .generate(delegate.persistence),  // Before migration: use SwiftData
                    application: .generate(),
                    device: .generate(),
                    featureFlags: .generate(.generate()),
                    widget: .generate(.shared),
                    migrationClient: migrationClient
                ),
                with: .init(groupID: Project.current.subscription.groupID)
            )
        }
    }

    init() {
        self.appGroupsName = Bundle.main.object(forInfoDictionaryKey: "AppGroupsName") as! String

        self.isSnapshot = ProcessInfo.processInfo.arguments.contains("snapshot")
    }
}

// swiftlint:enable force_try force_cast
