import XCTest
@testable import BookCore
@testable import BookModel
import ComposableArchitecture
import SearchClient

final class ScanFeatureTests: XCTestCase {
    private func makeBook(isbn: String = "9784815607852") -> SearchingBook {
        SearchingBook(
            title: "Test Book",
            author: "Test Author",
            price: 1000,
            affiliateURL: nil,
            imageURL: URL(string: "https://example.com/image.jpg")!,
            isbn: isbn,
            publisher: "Test Publisher",
            caption: nil,
            salesAt: "2024-01-01",
            registered: nil
        )
    }

    private func makeResponse(statusCode: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    @MainActor
    func test_captureChanged_startsWithISBN978_triggersUpdate() async {
        let book = makeBook()
        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        } withDependencies: {
            $0[SearchClient.self].search = { @Sendable _ in
                ([book], self.makeResponse(statusCode: 200))
            }
        }

        await store.send(.screen(.captureChanged("9784815607852"))) {
            $0.text = "9784815607852"
        }
        await store.receive(\.internal.update) {
            $0.requesting = true
        }
        await store.receive(\.internal.updated) {
            $0.requesting = false
            $0.item = book
        }
    }

    @MainActor
    func test_captureChanged_notStartingWith978_isIgnored() async {
        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        }

        await store.send(.screen(.captureChanged("1234567890")))
    }

    @MainActor
    func test_update_success_setsItem() async {
        let book = makeBook()
        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        } withDependencies: {
            $0[SearchClient.self].search = { @Sendable _ in
                ([book], self.makeResponse(statusCode: 200))
            }
        }

        await store.send(.screen(.captureChanged("9784815607852"))) {
            $0.text = "9784815607852"
        }
        await store.receive(\.internal.update) {
            $0.requesting = true
        }
        await store.receive(\.internal.updated) {
            $0.requesting = false
            $0.item = book
        }
    }

    @MainActor
    func test_update_bookNotFound_showsAlert() async {
        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        } withDependencies: {
            $0[SearchClient.self].search = { @Sendable _ in
                ([], self.makeResponse(statusCode: 200))
            }
        }

        await store.send(.screen(.captureChanged("9784815607852"))) {
            $0.text = "9784815607852"
        }
        await store.receive(\.internal.update) {
            $0.requesting = true
        }
        await store.receive(\.internal.updated) {
            $0.requesting = false
            $0.destination = .alert(.init(
                title: { .init("alert.title.not_found_book") },
                actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) },
                message: { .init("alert.message.not_found_book") }
            ))
        }
    }

    @MainActor
    func test_update_httpError_showsAlert() async {
        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        } withDependencies: {
            $0[SearchClient.self].search = { @Sendable _ in
                ([], self.makeResponse(statusCode: 500))
            }
        }

        await store.send(.screen(.captureChanged("9784815607852"))) {
            $0.text = "9784815607852"
        }
        await store.receive(\.internal.update) {
            $0.requesting = true
        }
        await store.receive(\.internal.updated) {
            $0.requesting = false
            $0.destination = .alert(AlertHelper.alert(from: self.makeResponse(statusCode: 500), action: .onCloseTapped))
        }
    }

    @MainActor
    func test_onRescanTapped_clearsItemAndText() async {
        var state = ScanFeature.State()
        state.item = makeBook()
        state.text = "9784815607852"

        let store = TestStore(initialState: state) {
            ScanFeature()
        }

        await store.send(.screen(.onRescanTapped)) {
            $0.item = nil
            $0.text = ""
        }
    }

    @MainActor
    func test_onSelected_sendsDelegateRegister() async {
        let book = makeBook()
        let store = TestStore(initialState: ScanFeature.State()) {
            ScanFeature()
        }

        await store.send(.screen(.onSelected(book)))
        await store.receive(\.delegate.register)
    }

    @MainActor
    func test_duplicateRequest_isPrevented() async {
        let book = makeBook()
        var state = ScanFeature.State()
        state.requesting = true
        state.text = "9784815607852"

        let store = TestStore(initialState: state) {
            ScanFeature()
        } withDependencies: {
            $0[SearchClient.self].search = { @Sendable _ in
                ([book], self.makeResponse(statusCode: 200))
            }
        }

        // Sending update while already requesting should be ignored
        await store.send(.internal(.update))
    }
}
