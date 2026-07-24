import XCTest
@testable import MigrationCore
import ComposableArchitecture

final class MigrationFeatureTests: XCTestCase {
    @MainActor
    func test_onAppear_migrationNeeded_setsIdleWithBookCount() async {
        let store = TestStore(initialState: MigrationFeature.State()) {
            MigrationFeature()
        } withDependencies: {
            $0.migrationClient.requiresMigration = { true }
            $0.migrationClient.getBookCount = { 42 }
        }

        await store.send(.screen(.onAppear))
        await store.receive(\.internal.checkMigrationNeeded) {
            $0.migrationState = .checking
        }
        await store.receive(\.internal.migrationCheckCompleted) {
            $0.migrationState = .idle
            $0.bookCount = 42
        }
    }

    @MainActor
    func test_onAppear_migrationNotNeeded_completedAndFinished() async {
        let store = TestStore(initialState: MigrationFeature.State()) {
            MigrationFeature()
        } withDependencies: {
            $0.migrationClient.requiresMigration = { false }
        }

        await store.send(.screen(.onAppear))
        await store.receive(\.internal.checkMigrationNeeded) {
            $0.migrationState = .checking
        }
        await store.receive(\.internal.migrationCheckCompleted) {
            $0.migrationState = .completed
        }
        await store.receive(\.external.migrationFinished)
    }

    @MainActor
    func test_startMigration_success_completedWithAlert() async {
        let store = TestStore(initialState: MigrationFeature.State(migrationState: .idle)) {
            MigrationFeature()
        } withDependencies: {
            $0.migrationClient.performMigration = {}
            $0.migrationClient.markCompleted = {}
        }

        await store.send(.screen(.startMigration)) {
            $0.migrationState = .migrating(progress: 0)
        }
        await store.receive(\.internal.performMigration)
        await store.receive(\.internal.migrationCompleted) {
            $0.migrationState = .completed
            $0.completionAlert = AlertState {
                TextState("alert.title.migration_completed")
            } actions: {
                ButtonState(action: .dismiss) {
                    TextState("button.title.close")
                }
            } message: {
                TextState("alert.message.migration_completed")
            }
        }
    }

    @MainActor
    func test_startMigration_failure_failedState() async {
        struct MigrationError: Error, LocalizedError {
            var errorDescription: String? { "Migration failed" }
        }

        let store = TestStore(initialState: MigrationFeature.State(migrationState: .idle)) {
            MigrationFeature()
        } withDependencies: {
            $0.migrationClient.performMigration = { throw MigrationError() }
        }

        await store.send(.screen(.startMigration)) {
            $0.migrationState = .migrating(progress: 0)
        }
        await store.receive(\.internal.performMigration)
        await store.receive(\.internal.migrationFailed) {
            $0.migrationState = .failed(error: "Migration failed")
        }
    }

    @MainActor
    func test_skipMigration_dismissCalled() async {
        let store = TestStore(initialState: MigrationFeature.State()) {
            MigrationFeature()
        }

        await store.send(.screen(.skipMigration))
    }

    @MainActor
    func test_alertDismiss_delegateAndExternal() async {
        var state = MigrationFeature.State(migrationState: .completed)
        state.completionAlert = AlertState {
            TextState("alert.title.migration_completed")
        } actions: {
            ButtonState(action: .dismiss) {
                TextState("button.title.close")
            }
        } message: {
            TextState("alert.message.migration_completed")
        }

        let store = TestStore(initialState: state) {
            MigrationFeature()
        }

        await store.send(.alert(.presented(.dismiss))) {
            $0.completionAlert = nil
        }
        await store.receive(\.delegate.migrationCompleted)
        await store.receive(\.external.migrationFinished)
    }

    @MainActor
    func test_checkMigrationNeeded_failure_failedState() async {
        struct CheckError: Error, LocalizedError {
            var errorDescription: String? { "Check failed" }
        }

        let store = TestStore(initialState: MigrationFeature.State()) {
            MigrationFeature()
        } withDependencies: {
            $0.migrationClient.requiresMigration = { throw CheckError() }
        }

        await store.send(.screen(.onAppear))
        await store.receive(\.internal.checkMigrationNeeded) {
            $0.migrationState = .checking
        }
        await store.receive(\.internal.migrationFailed) {
            $0.migrationState = .failed(error: "Check failed")
        }
    }
}
