import Testing
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

@MainActor
@Suite
struct BooksFeatureTests {
    @Test
    func task_fetch_setsGenresNewsAndSales() async {
        let genres = [makeGenre(), makeGenre(id: "001002", name: "文学・小説")]
        let newsBook = makeBook(isbn: "9784815607852")
        let salesBook = makeBook(isbn: "9784815607853")

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([newsBook], makeResponse(statusCode: 200))
                case .sales:
                    return ([salesBook], makeResponse(statusCode: 200))
                }
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched.success) {
            $0.genres = .init(uniqueElements: genres)
            $0.news = .init(uniqueElements: [newsBook])
            $0.sales = .init(uniqueElements: [salesBook])
        }
    }

    @Test
    func genreSelected_changesGenreAndRefetches() async {
        let newGenre = makeGenre(id: "001002", name: "文学・小説")
        let genres = [makeGenre(), newGenre]
        let newsBook = makeBook(isbn: "9784815607852")
        let salesBook = makeBook(isbn: "9784815607853")

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([newsBook], makeResponse(statusCode: 200))
                case .sales:
                    return ([salesBook], makeResponse(statusCode: 200))
                }
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.genreSelected(newGenre))) {
            $0.$genre.withLock { $0 = newGenre }
        }
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched.success) {
            $0.genres = .init(uniqueElements: genres)
            $0.news = .init(uniqueElements: [newsBook])
            $0.sales = .init(uniqueElements: [salesBook])
        }
    }

    @Test
    func onBookTapped_setsDestinationToBook() async {
        let book = makeBook()

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        }

        await store.send(.screen(.onBookTapped(book))) {
            $0.destination = .book(.make(book: book))
        }
    }

    @Test
    func fetch_failure_showsAlert() async {
        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { throw URLError(.notConnectedToInternet) }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched.failure) {
            $0.destination = .alert(
                AlertHelper.alert(from: URLError(.notConnectedToInternet), action: .onCloseTapped)
            )
        }
    }

    @Test
    func fetch_httpError_showsAlert() async {
        let genres = [makeGenre()]
        let response500 = makeResponse(statusCode: 500)

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([], response500)
                case .sales:
                    return ([], makeResponse(statusCode: 200))
                }
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched.success) {
            $0.destination = .alert(
                AlertHelper.alert(from: response500, action: .onCloseTapped)
            )
        }
    }

    @Test
    func fetch_registeredFlag_isSetForExistingBooks() async {
        let genres = [makeGenre()]
        let book1 = makeBook(isbn: "9784815607852")
        let book2 = makeBook(isbn: "9784815607853")

        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, kind in
                switch kind {
                case .new:
                    return ([book1, book2], makeResponse(statusCode: 200))
                case .sales:
                    return ([], makeResponse(statusCode: 200))
                }
            }
            $0[ShelfClient.self].exists = { @Sendable isbn in
                isbn.rawValue == "9784815607852"
            }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched.success) {
            $0.genres = .init(uniqueElements: genres)
            $0.news = .init(uniqueElements: [
                makeBook(isbn: "9784815607852", registered: true),
                makeBook(isbn: "9784815607853", registered: false),
            ])
            $0.sales = []
        }
    }

    @Test
    func onRefresh_refetches() async {
        let genres = [makeGenre()]
        let store = TestStore(initialState: BooksFeature.State.make()) {
            BooksFeature()
        } withDependencies: {
            $0[GenreClient.self].fetch = { genres }
            $0[BookClient.self].fetch = { @Sendable _, _ in
                ([], makeResponse(statusCode: 200))
            }
            $0[ShelfClient.self].exists = { @Sendable _ in false }
        }

        await store.send(.screen(.onRefresh))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched.success) {
            $0.genres = .init(uniqueElements: genres)
        }
    }

    @Test
    func alertDismiss_clearsDestination() async {
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
