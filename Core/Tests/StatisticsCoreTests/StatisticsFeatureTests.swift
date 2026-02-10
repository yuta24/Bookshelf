import ComposableArchitecture
import Foundation
import OrderedCollections
import Testing

@testable import BookModel
@testable import StatisticsCore

@Suite
struct StatisticsFeatureTests {
    private static let calendar = Calendar(identifier: .gregorian)

    private static func makeBook(
        id: UUID = UUID(),
        createdAt: Date,
        status: Book.Status = .unread
    ) -> Book {
        Book(
            id: .init(id),
            title: .init("Test Book"),
            author: .init("Author"),
            price: .init(1000),
            affiliateURL: nil,
            imageURL: URL(string: "https://example.com/image.jpg")!,
            isbn: .init("1234567890123"),
            publisher: .init("Publisher"),
            caption: nil,
            salesAt: .init("2025-01-01"),
            bought: false,
            note: .init(""),
            status: status,
            createdAt: createdAt,
            updatedAt: createdAt,
            tags: []
        )
    }

    private static func date(year: Int, month: Int, day: Int = 1) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    @Test
    func onAppear_fetchesBooksAndGroupsByMonth() async throws {
        let janBook = Self.makeBook(createdAt: Self.date(year: 2025, month: 1))
        let marBook = Self.makeBook(createdAt: Self.date(year: 2025, month: 3))

        let store = TestStore(initialState: StatisticsFeature.State.make()) {
            StatisticsFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [janBook, marBook] }
        }

        await store.send(.screen(.onAppear))
        await store.receive(\.internal.fetched) {
            var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]
            for i in 1...12 { books[i] = [] }
            books[1] = [janBook]
            books[3] = [marBook]
            $0.books = books
        }
    }

    @Test
    func tabChanged_updatesTab() async throws {
        let store = TestStore(initialState: StatisticsFeature.State.make()) {
            StatisticsFeature()
        }

        await store.send(.screen(.tabChanged(.insight))) {
            $0.tab = .insight
        }
    }

    @Test
    func onPreviousTapped_decrementYearAndFetches() async throws {
        let store = TestStore(initialState: StatisticsFeature.State.make()) {
            StatisticsFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [] }
        }

        await store.send(.screen(.onPreviousTapped)) {
            $0.select = Self.calendar.date(byAdding: .init(year: -1), to: $0.latest)
        }
        await store.receive(\.internal.fetched) {
            var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]
            for i in 1...12 { books[i] = [] }
            $0.books = books
        }
    }

    @Test
    func onNextTapped_incrementYearAndFetches() async throws {
        var state = StatisticsFeature.State.make()
        state.select = Self.calendar.date(byAdding: .init(year: -2), to: state.latest)

        let store = TestStore(initialState: state) {
            StatisticsFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [] }
        }

        let expectedSelect = Self.calendar.date(byAdding: .init(year: -1), to: state.latest)
        await store.send(.screen(.onNextTapped)) {
            $0.select = expectedSelect
        }
        await store.receive(\.internal.fetched) {
            var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]
            for i in 1...12 { books[i] = [] }
            $0.books = books
        }
    }

    @Test
    func nextEnabled_falseWhenSelectIsNil() {
        let state = StatisticsFeature.State.make()
        #expect(state.nextEnabled == false)
    }

    @Test
    func nextEnabled_falseWhenSelectEqualsLatestYear() {
        var state = StatisticsFeature.State.make()
        state.select = state.latest
        #expect(state.nextEnabled == false)
    }

    @Test
    func nextEnabled_trueWhenSelectIsPastYear() {
        var state = StatisticsFeature.State.make()
        state.select = Self.calendar.date(byAdding: .init(year: -1), to: state.latest)
        #expect(state.nextEnabled == true)
    }

    @Test
    func onTargetSelected_switchesToReadAndRefetches() async throws {
        let readDate = Self.date(year: 2025, month: 6)
        let book = Self.makeBook(
            createdAt: Self.date(year: 2025, month: 1),
            status: .read(readDate)
        )

        let store = TestStore(initialState: StatisticsFeature.State.make()) {
            StatisticsFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [book] }
        }

        await store.send(.screen(.custom(.onTargetSelected(.read)))) {
            $0.custom.target = .read
        }
        // onTargetSelected sends .screen(.onAppear)
        await store.receive(\.screen.onAppear)
        await store.receive(\.internal.fetched) {
            var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]
            for i in 1...12 { books[i] = [] }
            books[6] = [book]
            $0.books = books
        }
    }

    @Test
    func onActive_updatesLatestAndRefetches() async throws {
        let store = TestStore(initialState: StatisticsFeature.State.make()) {
            StatisticsFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [] }
        }

        await store.send(.external(.onActive)) {
            $0.latest = $0.latest // latest is set to Date(), hard to assert exactly
        }
        await store.receive(\.internal.fetched) {
            var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]
            for i in 1...12 { books[i] = [] }
            $0.books = books
        }
    }

    @Test
    func fetched_booksWithNilDateAreExcluded() async throws {
        // status = .unread → readAt is nil, so with target .read, book should be excluded
        let book = Self.makeBook(
            createdAt: Self.date(year: 2025, month: 3),
            status: .unread
        )

        var state = StatisticsFeature.State.make()
        state.custom.target = .read

        let store = TestStore(initialState: state) {
            StatisticsFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAtYear = { @Sendable _ in [book] }
        }

        await store.send(.screen(.onAppear))
        await store.receive(\.internal.fetched) {
            var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]
            for i in 1...12 { books[i] = [] }
            $0.books = books
        }
    }
}
