import XCTest
@testable import BookCore
@testable import BookModel
import ComposableArchitecture
import BookClient
import GenreClient
import GenreModel
import ShelfClient

private func makeBook(isbn: String = "9784815607852", registered: Bool? = nil) -> SearchingBook {
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
        registered: registered
    )
}

private func makeGenre(id: String = "001001", name: String = "漫画（コミック）") -> Genre {
    Genre(id: .init(id), name: name)
}

private func makeResponse(statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
}

// NOTE: Uses `\.internal.fetched` instead of `\.internal.fetched.success` / `.failure`
// to work around a Swift 6.2.3 compiler crash in IRGen (KeyPath + CasePathable + Result).

final class BooksFeatureTests: XCTestCase {

    // MARK: - task fetch

    @MainActor
    func test_task_fetch_setsGenresNewsAndSales() async {
        let genres = [makeGenre(), makeGenre(id: "001002", name: "文学・小説")]
        let newsBook = makeBook(isbn: "9784815607852")
        let salesBook = makeBook(isbn: "9784815607853")
        let response200 = makeResponse(statusCode: 200)

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([newsBook], response200)
                case .sales:
                    return ([salesBook], response200)
                }
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.genres = .init(uniqueElements: genres)
            $0.news = .init(uniqueElements: [makeBook(isbn: "9784815607852", registered: false)])
            $0.sales = .init(uniqueElements: [makeBook(isbn: "9784815607853", registered: false)])
        }
    }

    // MARK: - genreSelected

    @MainActor
    func test_genreSelected_changesGenreAndRefetches() async {
        let newGenre = makeGenre(id: "001002", name: "文学・小説")
        let genres = [makeGenre(), newGenre]
        let newsBook = makeBook(isbn: "9784815607852")
        let salesBook = makeBook(isbn: "9784815607853")
        let response200 = makeResponse(statusCode: 200)

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([newsBook], response200)
                case .sales:
                    return ([salesBook], response200)
                }
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.genreSelected(newGenre))) {
            $0.$genre.withLock { $0 = newGenre }
        }
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.genres = .init(uniqueElements: genres)
            $0.news = .init(uniqueElements: [makeBook(isbn: "9784815607852", registered: false)])
            $0.sales = .init(uniqueElements: [makeBook(isbn: "9784815607853", registered: false)])
        }
    }

    // MARK: - onBookTapped

    @MainActor
    func test_onBookTapped_setsDestinationToBook() async {
        let book = makeBook()

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        }

        await store.send(.screen(.onBookTapped(book))) {
            $0.destination = .book(.make(book: book))
        }
    }

    // MARK: - fetch failure

    @MainActor
    func test_fetch_failure_showsAlert() async {
        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { throw URLError(.notConnectedToInternet) }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.destination = .alert(
                AlertHelper.alert(from: URLError(.notConnectedToInternet), action: .onCloseTapped)
            )
        }
    }

    // MARK: - fetch httpError

    @MainActor
    func test_fetch_httpError_showsAlert() async {
        let genres = [makeGenre()]
        let response500 = makeResponse(statusCode: 500)
        let response200 = makeResponse(statusCode: 200)

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([], response500)
                case .sales:
                    return ([], response200)
                }
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.destination = .alert(
                AlertHelper.alert(from: response500, action: .onCloseTapped)
            )
        }
    }

    // MARK: - registered flag

    @MainActor
    func test_fetch_registeredFlag_isSetForExistingBooks() async {
        let genres = [makeGenre()]
        let book1 = makeBook(isbn: "9784815607852")
        let book2 = makeBook(isbn: "9784815607853")
        let response200 = makeResponse(statusCode: 200)

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([book1, book2], response200)
                case .sales:
                    return ([], response200)
                }
            }
            $0[ShelfClient.self].exists = { @Sendable isbn in
                isbn.rawValue == "9784815607852"
            }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.genres = .init(uniqueElements: genres)
            $0.news = .init(uniqueElements: [
                makeBook(isbn: "9784815607852", registered: true),
                makeBook(isbn: "9784815607853", registered: false),
            ])
            $0.sales = []
        }
    }

    // MARK: - onRefresh

    @MainActor
    func test_onRefresh_refetches() async {
        let genres = [makeGenre()]
        let response200 = makeResponse(statusCode: 200)

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, _ in
                ([], response200)
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.onRefresh))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.genres = .init(uniqueElements: genres)
        }
    }

    // MARK: - alert dismiss

    @MainActor
    func test_alertDismiss_clearsDestination() async {
        var state = BooksFeature.State.make()
        state.destination = .alert(
            AlertHelper.alert(from: URLError(.notConnectedToInternet), action: .onCloseTapped)
        )

        let store = TestStore(initialState: state) {
            BooksFeature()
        }

        await store.send(.destination(.presented(.alert(.onCloseTapped)))) {
            $0.destination = nil
        }
    }
}
