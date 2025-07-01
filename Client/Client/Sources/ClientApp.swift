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

@main
struct ClientApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var delegate

    var body: some Scene {
        WindowGroup {
            RootBuilder.build(
                gateway: .init(
                    analyticsClient: .generate(),
                    bookClient: .generate(.shared),
                    genreClient: .generate(.remoteConfig()),
                    preReleaseNotificationClient: .generate(),
                    remindClient: .generate(),
                    searchClient: .generate(.shared),
                    shelfClient: ProcessInfo.processInfo.arguments.contains("snapshot")
                        ? .snapshot(delegate.persistence) : .generate(delegate.persistence),
                    syncClient: {
                        // swiftlint:disable force_try
                        let repository = SyncClient.generate { enabled in
                            try! delegate.persistence.update(with: enabled)
                        }
                        try! delegate.persistence.update(with: repository.fetch()?.enabled ?? false)
                        // swiftlint:enable force_try
                        return repository
                    }(),
                    tagClient: .generate(delegate.persistence),
                    application: .generate(),
                    device: .generate(),
                    featureFlags: .generate(.generate()),
                    widget: .generate(.shared)
                ),
                with: .init(groupID: Project.current.subscription.groupID)
            )
        }
    }
}
