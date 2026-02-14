import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import SettingsCore
import Application
import Device
import FeatureFlags
import RemindClient
import SyncClient
import MigrationCore
import ShelfClient
import Foundation
@testable import Presentation

@MainActor
struct SettingsScreenSnapshotTests {
    @Test
    func settingsScreenDefault() {
        let store = Store(initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.test")) {
            SettingsFeature()
        } withDependencies: {
            $0[Application.self].version = { "1.0.0" }
            $0[Application.self].build = { 1 }
            $0[Device.self].isProfileInstalled = { false }
            $0[FeatureFlags.self].enablePurchase = { false }
            $0[FeatureFlags.self].enableNotification = { false }
            $0[FeatureFlags.self].enableBooks = { false }
            $0[FeatureFlags.self].enableImport = { false }
            $0[FeatureFlags.self].enableExport = { false }
            $0[RemindClient.self].fetch = { .disabled }
            $0[SyncClient.self].fetch = { nil }
            $0[MigrationClient.self].isCompleted = { true }
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [] }
        }
        let view = SettingsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }

    @Test
    func settingsScreenWithSync() {
        let store = Store(initialState: SettingsFeature.State.make(isSyncEnabled: true, groupID: "group.com.test")) {
            SettingsFeature()
        } withDependencies: {
            $0[Application.self].version = { "1.0.0" }
            $0[Application.self].build = { 1 }
            $0[Device.self].isProfileInstalled = { false }
            $0[FeatureFlags.self].enablePurchase = { false }
            $0[FeatureFlags.self].enableNotification = { false }
            $0[FeatureFlags.self].enableBooks = { false }
            $0[FeatureFlags.self].enableImport = { false }
            $0[FeatureFlags.self].enableExport = { false }
            $0[RemindClient.self].fetch = { .disabled }
            $0[SyncClient.self].fetch = { .init(enabled: true) }
            $0[MigrationClient.self].isCompleted = { true }
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [] }
        }
        let view = SettingsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
