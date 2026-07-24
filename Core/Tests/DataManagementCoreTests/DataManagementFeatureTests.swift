import XCTest
@testable import DataManagementCore
import ComposableArchitecture
import DataClient

final class DataManagementFeatureTests: XCTestCase {
    @MainActor
    func test_onLoad_exportSuccess_jsonSet() async {
        let store = TestStore(initialState: DataManagementFeature.State()) {
            DataManagementFeature()
        } withDependencies: {
            $0[DataClient.self].export = { "{\"books\":[]}" }
        }

        await store.send(.screen(.onLoad))
        await store.receive(\.internal.loaded) {
            $0.json = "{\"books\":[]}"
        }
    }

    @MainActor
    func test_onLoad_exportFailure_alertShown() async {
        struct ExportError: Error, LocalizedError {
            var errorDescription: String? { "Export failed" }
        }

        let store = TestStore(initialState: DataManagementFeature.State()) {
            DataManagementFeature()
        } withDependencies: {
            $0[DataClient.self].export = { throw ExportError() }
        }

        await store.send(.screen(.onLoad))
        await store.receive(\.internal.loaded) {
            $0.alert = AlertState {
                TextState(String(localized: "alert.title.load_failed"))
            } actions: {
                ButtonState(action: .dismiss) {
                    TextState("OK")
                }
            } message: {
                TextState("Export failed")
            }
        }
    }

    @MainActor
    func test_imported_success_alertShown() async {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.json")
        try! Data("{\"books\":[]}".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = TestStore(initialState: DataManagementFeature.State()) {
            DataManagementFeature()
        } withDependencies: {
            $0[DataClient.self].import = { @Sendable _ in }
        }

        await store.send(.screen(.imported(tempURL)))
        await store.receive(\.internal.imported) {
            $0.alert = AlertState {
                TextState(String(localized: "import_completed_title"))
            } actions: {
                ButtonState(action: .dismiss) {
                    TextState("OK")
                }
            } message: {
                TextState(String(localized: "alert.message.import_success_simple"))
            }
        }
    }

    @MainActor
    func test_imported_failure_errorAlertShown() async {
        struct ImportError: Error, LocalizedError {
            var errorDescription: String? { "Import failed" }
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.json")
        try! Data("{\"books\":[]}".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = TestStore(initialState: DataManagementFeature.State()) {
            DataManagementFeature()
        } withDependencies: {
            $0[DataClient.self].import = { @Sendable _ in throw ImportError() }
        }

        await store.send(.screen(.imported(tempURL)))
        await store.receive(\.internal.imported) {
            $0.alert = AlertState {
                TextState(String(localized: "alert.title.import_failed"))
            } actions: {
                ButtonState(action: .dismiss) {
                    TextState("OK")
                }
            } message: {
                TextState("Import failed")
            }
        }
    }

    @MainActor
    func test_alertDismiss_alertCleared() async {
        var state = DataManagementFeature.State()
        state.alert = AlertState {
            TextState("Test")
        } actions: {
            ButtonState(action: .dismiss) {
                TextState("OK")
            }
        }

        let store = TestStore(initialState: state) {
            DataManagementFeature()
        }

        await store.send(.alert(.presented(.dismiss))) {
            $0.alert = nil
        }
    }
}
