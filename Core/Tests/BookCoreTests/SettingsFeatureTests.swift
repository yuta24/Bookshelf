import XCTest
@testable import SettingsCore
import ComposableArchitecture
import RemindModel
import RemindClient
import SyncClient
import Application
import Device
import FeatureFlags
import MigrationCore
import SyncModel
import Foundation

final class SettingsFeatureTests: XCTestCase {

    // MARK: - onLoad

    @MainActor
    func test_onLoad_setsFeatureFlags() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        } withDependencies: {
            $0[FeatureFlags.self].enablePurchase = { false }
            $0[MigrationClient.self].isCompleted = { true }
        }

        await store.send(.screen(.onLoad)) {
            $0.enablePurchase = false
            $0.isMigrationCompleted = true
        }
    }

    // MARK: - task (enablePurchase = false)

    @MainActor
    func test_task_withoutPurchase_loadsSettings() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        } withDependencies: {
            $0[SyncClient.self].fetch = { Sync(enabled: true) }
            $0[RemindClient.self].fetch = { .disabled }
            $0[Application.self].version = { "1.0.0" }
            $0[Application.self].build = { 42 }
            $0[Device.self].isProfileInstalled = { false }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.load)
        await store.receive(\.internal.loaded) {
            $0.isSyncEnabled = true
            $0.remind = .disabled
            $0.version = "1.0.0"
            $0.build = "42"
            $0.isProfileInstalled = false
        }
    }

    // MARK: - syncEnabledChanged

    @MainActor
    func test_syncEnabledChanged_updatesState() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        } withDependencies: {
            $0[SyncClient.self].update = { _ in }
        }

        await store.send(.screen(.syncEnabledChanged(true))) {
            $0.isSyncEnabled = true
        }
    }

    // MARK: - remindEnabledChanged

    @MainActor
    func test_remindEnabledChanged_true_setsDefaultRemind() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        } withDependencies: {
            $0[RemindClient.self].update = { _ in }
        }

        await store.send(.screen(.remindEnabledChanged(true))) {
            $0.remind = .make(.saturday)
        }
    }

    @MainActor
    func test_remindEnabledChanged_false_disablesRemind() async {
        var initialState = SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        initialState.remind = .make(.saturday)

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        } withDependencies: {
            $0[RemindClient.self].update = { _ in }
        }

        await store.send(.screen(.remindEnabledChanged(false))) {
            $0.remind = .disabled
        }
    }

    // MARK: - dayOfWeekChanged

    @MainActor
    func test_dayOfWeekChanged_updatesRemindSetting() async {
        var initialState = SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        initialState.remind = .make(.saturday)

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        } withDependencies: {
            $0[RemindClient.self].update = { _ in }
        }

        await store.send(.screen(.dayOfWeekChanged(.monday))) {
            $0.remind = .enabled(.init(dayOfWeek: .monday, hour: 9))
        }
    }

    @MainActor
    func test_dayOfWeekChanged_whenDisabled_doesNothing() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        }

        await store.send(.screen(.dayOfWeekChanged(.monday)))
    }

    // MARK: - navigation

    @MainActor
    func test_onSupportTapped_presentsSupport() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        }

        await store.send(.screen(.onSupportTapped)) {
            $0.destination = .support(.init(groupID: "group.com.bivre.bookshelf"))
        }
    }

    @MainActor
    func test_onMigrationTapped_presentsMigration() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        }

        await store.send(.screen(.onMigrationTapped)) {
            $0.destination = .migration(.init())
        }
    }

    @MainActor
    func test_onDataManagementTapped_presentsDataManagement() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        }

        await store.send(.screen(.onDataManagementTapped)) {
            $0.destination = .dataManagement(.init())
        }
    }

    @MainActor
    func test_onNetworkTapped_activatesNetwork() async {
        let store = TestStore(
            initialState: SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        ) {
            SettingsFeature()
        }

        await store.send(.screen(.onNetworkTapped)) {
            $0.isNetworkActived = true
        }
    }

    @MainActor
    func test_onNetworkDismissed_deactivatesNetwork() async {
        var initialState = SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        initialState.isNetworkActived = true

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        }

        await store.send(.screen(.onNetworkDismissed(false))) {
            $0.isNetworkActived = false
        }
    }

    // MARK: - destination dismiss

    @MainActor
    func test_destinationDismiss_clearsDestination() async {
        var initialState = SettingsFeature.State.make(isSyncEnabled: false, groupID: "group.com.bivre.bookshelf")
        initialState.destination = .dataManagement(.init())

        let store = TestStore(initialState: initialState) {
            SettingsFeature()
        }

        await store.send(.destination(.dismiss)) {
            $0.destination = nil
        }
    }
}
