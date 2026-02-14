import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
import SettingsCore
import Foundation
@testable import Presentation

@MainActor
struct SettingsScreenSnapshotTests {
    @Test
    func settingsScreenDefault() {
        let store = Store(initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.test")) {
            SettingsFeature()
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
        }
        let view = SettingsScreen(store: store)

        withSnapshotTesting(record: .failed) {
            assertSnapshot(of: view, as: .image(perceptualPrecision: 0.9, layout: .screen))
        }
    }
}
