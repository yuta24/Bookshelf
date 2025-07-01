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

import ComposableArchitecture

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
        public var genreClient: GenreClient
        public var preReleaseNotificationClient: PreReleaseNotificationClient
        public var remindClient: RemindClient
        public var searchClient: SearchClient
        public var shelfClient: ShelfClient
        public var syncClient: SyncClient
        public var tagClient: TagClient
        public var application: Application
        public var device: Device
        public var featureFlags: FeatureFlags
        public var widget: WidgetUpdater

        public init(
            analyticsClient: AnalyticsClient,
            bookClient: BookClient,
            genreClient: GenreClient,
            preReleaseNotificationClient: PreReleaseNotificationClient,
            remindClient: RemindClient,
            searchClient: SearchClient,
            shelfClient: ShelfClient,
            syncClient: SyncClient,
            tagClient: TagClient,
            application: Application,
            device: Device,
            featureFlags: FeatureFlags,
            widget: WidgetUpdater
        ) {
            self.analyticsClient = analyticsClient
            self.bookClient = bookClient
            self.genreClient = genreClient
            self.preReleaseNotificationClient = preReleaseNotificationClient
            self.remindClient = remindClient
            self.searchClient = searchClient
            self.shelfClient = shelfClient
            self.syncClient = syncClient
            self.tagClient = tagClient
            self.application = application
            self.device = device
            self.featureFlags = featureFlags
            self.widget = widget
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
                        .dependency(gateway.tagClient)
                        .dependency(gateway.application)
                        .dependency(gateway.device)
                        .dependency(gateway.featureFlags)
                        .dependency(gateway.widget)
                        ._printChanges()
                }
            ))
    }
}
