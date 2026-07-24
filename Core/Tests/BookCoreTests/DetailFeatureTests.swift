import XCTest
@testable import BookCore
@testable import BookModel
import ComposableArchitecture
import PreReleaseNotificationModel
import PreReleaseNotificationClient
import SearchClient
import ShelfClient
import WidgetUpdater
import AnalyticsClient

final class DetailFeatureTests: XCTestCase {
    private static let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private static let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private static func makeBook(
        id: UUID = fixedUUID,
        bought: Bool = false,
        note: String = "",
        status: Book.Status = .unread,
        isbn: String = "9784815607852",
        tags: [Tag] = []
    ) -> Book {
        Book(
            id: .init(rawValue: id),
            title: .init(rawValue: "Test Book"),
            author: .init(rawValue: "Test Author"),
            price: .init(rawValue: 1000),
            affiliateURL: nil,
            imageURL: URL(string: "https://example.com/image.jpg")!,
            isbn: .init(rawValue: isbn),
            publisher: .init(rawValue: "Test Publisher"),
            caption: nil,
            salesAt: .init(rawValue: "2024-01-01"),
            bought: bought,
            note: .init(rawValue: note),
            status: status,
            createdAt: fixedDate,
            updatedAt: fixedDate,
            tags: tags
        )
    }

    private static func makeResponse() -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
    }

    // MARK: - boughtChanged

    @MainActor
    func test_boughtChanged_updatesBookAndCallsShelfClient() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { @Sendable updatedBook in
                updatedBook
            }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
        }

        await store.send(.screen(.boughtChanged(true))) {
            $0.$book.withLock { $0.bought = true }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - statusChanged(.read)

    @MainActor
    func test_statusChanged_read_setsReadWithDate() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0.date = .constant(Self.fixedDate)
            $0[ShelfClient.self].update = { @Sendable b in b }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
        }

        await store.send(.screen(.statusChanged(.read))) {
            $0.$book.withLock { $0.status = .read(Self.fixedDate) }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - statusChanged(.reading)

    @MainActor
    func test_statusChanged_reading() async {
        let book = Self.makeBook(status: .unread)
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { @Sendable b in b }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
        }

        await store.send(.screen(.statusChanged(.reading))) {
            $0.$book.withLock { $0.status = .reading }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - statusChanged(.unread)

    @MainActor
    func test_statusChanged_unread() async {
        let book = Self.makeBook(status: .reading)
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { @Sendable b in b }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
        }

        await store.send(.screen(.statusChanged(.unread))) {
            $0.$book.withLock { $0.status = .unread }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - noteChanged

    @MainActor
    func test_noteChanged_updatesNoteAndSaves() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { @Sendable b in b }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
        }

        await store.send(.screen(.noteChanged("Hello"))) {
            $0.$book.withLock { $0.note = .init(rawValue: "Hello") }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - onDeleteTapped → confirmation → delete

    @MainActor
    func test_onDeleteTapped_showsConfirmation_thenDeletes() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0[ShelfClient.self].delete = { @Sendable _ in }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
            $0[AnalyticsClient.self].log = { @Sendable _, _ in }
            $0.dismiss = DismissEffect { }
        }

        await store.send(.screen(.onDeleteTapped)) {
            $0.confirmation = .init(
                titleVisibility: .visible,
                title: { .init("confirm.delete_book") },
                actions: {
                    ButtonState(role: .cancel, action: .onCancelTapped, label: { .init("button.title.cancel") })
                    ButtonState(role: .destructive, action: .onDeleteTapped, label: { .init("button.title.delete") })
                }
            )
        }
        await store.send(.confirmationDialog(.presented(.onDeleteTapped))) {
            $0.confirmation = nil
        }
        await store.receive(\.books.remove) {
            let id = book.id
            $0.$books.withLock { $0.remove(id: id) }
        }
        await store.receive(\.books.removed)
    }

    // MARK: - onTagTapped

    @MainActor
    func test_onTagTapped_setsDestinationToEdit() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        }

        await store.send(.screen(.onTagTapped)) {
            $0.destination = .edit(.init(book: bookShared, items: []))
        }
    }

    // MARK: - refreshImage

    @MainActor
    func test_refreshImage_updatesImageURL() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let newImageURL = URL(string: "https://example.com/new.jpg")!
        let searchingBook = SearchingBook(
            title: "Test Book",
            author: "Test Author",
            price: 1000,
            affiliateURL: nil,
            imageURL: newImageURL,
            isbn: "9784815607852",
            publisher: "Test Publisher",
            caption: nil,
            salesAt: "2024-01-01",
            registered: nil
        )

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        } withDependencies: {
            $0[SearchClient.self].search = { @Sendable _ in
                ([searchingBook], Self.makeResponse())
            }
            $0[ShelfClient.self].update = { @Sendable b in b }
            $0[WidgetUpdater.self].setNeedNotify = { @Sendable in }
        }

        await store.send(.screen(.refreshImage))
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - disablePreReleaseNotification

    @MainActor
    func test_disablePreReleaseNotification_removesNotification() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let notification = PreReleaseNotification(
            bookId: book.id,
            bookTitle: "Test Book",
            releaseDate: Self.fixedDate,
            notificationDate: Self.fixedDate
        )

        var state = DetailFeature.State.make(book: bookShared)
        state.preReleaseNotification = notification

        let store = TestStore(initialState: state) {
            DetailFeature()
        } withDependencies: {
            $0[PreReleaseNotificationClient.self].remove = { @Sendable _ in }
        }

        await store.send(.screen(.disablePreReleaseNotification)) {
            $0.preReleaseNotification = nil
        }
    }

    // MARK: - preReleaseNotificationLoaded

    @MainActor
    func test_preReleaseNotificationLoaded_setsNotification() async {
        let book = Self.makeBook()
        @Shared(.books) var books: IdentifiedArrayOf<Book> = [book]
        let bookShared = Shared($books[id: book.id])!

        let notification = PreReleaseNotification(
            bookId: book.id,
            bookTitle: "Test Book",
            releaseDate: Self.fixedDate,
            notificationDate: Self.fixedDate
        )

        let store = TestStore(initialState: DetailFeature.State.make(book: bookShared)) {
            DetailFeature()
        }

        await store.send(.screen(.preReleaseNotificationLoaded(notification))) {
            $0.preReleaseNotification = notification
        }
    }
}
