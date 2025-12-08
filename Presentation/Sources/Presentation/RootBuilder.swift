public import SwiftUI

public import AnalyticsClient

public import BookClient

public import GenreClient

public import PreReleaseNotificationClient

public import RemindClient

public import SearchClient

public import ShelfClient

public import SyncClient

public import TagClient

public import Application

public import Device

public import FeatureFlags

public import WidgetUpdater

public import MigrationCore

import ComposableArchitecture
import GRDB
import SQLiteData

public enum RootBuilder {
    public struct Configuratoin {
        public var groupID: String

        public init(groupID: String) {
            self.groupID = groupID
        }
    }

    public struct Gateway {
        public var analyticsClient: AnalyticsClient
        public var bookClient: BookClient
        public var database: any DatabaseWriter
        public var genreClient: GenreClient
        public var preReleaseNotificationClient: PreReleaseNotificationClient
        public var remindClient: RemindClient
        public var searchClient: SearchClient
        public var shelfClient: ShelfClient
        public var syncClient: SyncClient
        public var syncEngine: SyncEngine
        public var tagClient: TagClient
        public var application: Application
        public var device: Device
        public var featureFlags: FeatureFlags
        public var widget: WidgetUpdater
        public var migrationClient: MigrationClient

        public init(
            analyticsClient: AnalyticsClient,
            bookClient: BookClient,
            database: any DatabaseWriter,
            genreClient: GenreClient,
            preReleaseNotificationClient: PreReleaseNotificationClient,
            remindClient: RemindClient,
            searchClient: SearchClient,
            shelfClient: ShelfClient,
            syncClient: SyncClient,
            syncEngine: SyncEngine,
            tagClient: TagClient,
            application: Application,
            device: Device,
            featureFlags: FeatureFlags,
            widget: WidgetUpdater,
            migrationClient: MigrationClient
        ) {
            self.analyticsClient = analyticsClient
            self.bookClient = bookClient
            self.database = database
            self.genreClient = genreClient
            self.preReleaseNotificationClient = preReleaseNotificationClient
            self.remindClient = remindClient
            self.searchClient = searchClient
            self.shelfClient = shelfClient
            self.syncClient = syncClient
            self.syncEngine = syncEngine
            self.tagClient = tagClient
            self.application = application
            self.device = device
            self.featureFlags = featureFlags
            self.widget = widget
            self.migrationClient = migrationClient
        }
    }

    @MainActor
    public static func build(gateway: Gateway, with configuration: Configuratoin) -> some View {
        RootScreen(
            store: .init(
                initialState: .init(top: .make(groupID: configuration.groupID)),
                reducer: {
                    RootFeature()
                        .dependency(gateway.analyticsClient)
                        .dependency(gateway.bookClient)
                        .dependency(gateway.genreClient)
                        .dependency(gateway.preReleaseNotificationClient)
                        .dependency(gateway.remindClient)
                        .dependency(gateway.searchClient)
                        .dependency(gateway.shelfClient)
                        .dependency(gateway.syncClient)
                        .dependency(gateway.syncEngine)
                        .dependency(gateway.tagClient)
                        .dependency(gateway.application)
                        .dependency(gateway.device)
                        .dependency(gateway.featureFlags)
                        .dependency(gateway.widget)
                        .dependency(gateway.migrationClient)
                        ._printChanges()
                }
            ))
    }
}
