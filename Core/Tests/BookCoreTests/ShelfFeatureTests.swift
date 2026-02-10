import Foundation
import Testing
import ComposableArchitecture
@testable import BookCore
@testable import BookModel
import ShelfClient
import FeatureFlags

private typealias Tag = BookModel.Tag

@MainActor
@Suite
struct ShelfFeatureTests {
    private static let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private static let fixedUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private static func makeBook(
        id: UUID = fixedUUID,
        title: String = "Test Book",
        author: String = "Test Author",
        tags: [Tag] = []
    ) -> Book {
        Book(
            id: .init(rawValue: id),
            title: .init(rawValue: title),
            author: .init(rawValue: author),
            price: .init(rawValue: 1000),
            affiliateURL: nil,
            imageURL: URL(string: "https://example.com/image.jpg")!,
            isbn: .init(rawValue: "9784815607852"),
            publisher: .init(rawValue: "Test Publisher"),
            caption: nil,
            salesAt: .init(rawValue: "2024-01-01"),
            bought: false,
            note: .init(rawValue: ""),
            status: .unread,
            createdAt: fixedDate,
            updatedAt: fixedDate,
            tags: tags
        )
    }

    private static func makeTag(id: Int = 0, name: String = "Swift") -> Tag {
        Tag(
            id: .init(UUID(id)),
            name: name,
            createdAt: fixedDate,
            updatedAt: fixedDate
        )
    }

    // MARK: - task → books(.load) → 書籍一覧がロードされる

    @Test
    func task_loadBooks() async {
        let book = Self.makeBook()
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAll = { @Sendable _ in [book] }
            $0[FeatureFlags.self].enableImport = { false }
            $0[FeatureFlags.self].enableExport = { false }
            $0.continuousClock = ImmediateClock()
        }
        store.exhaustivity = .off

        await store.send(.screen(.task))
        await store.receive(\.books.load)
        await store.receive(\.books.loaded)
        store.state.$books.withLock { #expect($0 == .init(uniqueElements: [book])) }
    }

    // MARK: - onLayoutChanged → layout が変更される

    @Test
    func onLayoutChanged_updatesLayout() async {
        let store = TestStore(initialState: ShelfFeature.State.make(layout: .list)) {
            ShelfFeature()
        }
        store.exhaustivity = .off

        await store.send(.screen(.onLayoutChanged(.grid)))
        store.state.$layout.withLock { #expect($0 == .grid) }
    }

    // MARK: - onTextChanged → text が変更され items がフィルタされる

    @Test
    func onTextChanged_updatesTextAndFiltersItems() async {
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        }

        await store.send(.screen(.onTextChanged("Swift"))) {
            $0.text = "Swift"
        }
    }

    // MARK: - onTagTapped → 選択タグが除去される

    @Test
    func onTagTapped_removesTag() async {
        let tag = Self.makeTag()
        var state = ShelfFeature.State.make()
        state.tags = [tag]

        let store = TestStore(initialState: state) {
            ShelfFeature()
        }

        await store.send(.screen(.onTagTapped(tag))) {
            $0.tags = []
        }
    }

    // MARK: - onTagsTapped → destination が .tags になる

    @Test
    func onTagsTapped_setsDestinationToTags() async {
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        }

        await store.send(.screen(.onTagsTapped)) {
            $0.destination = .tags(.init(tags: .init(), selected: []))
        }
    }

    // MARK: - onSelected → destination が .detail になる

    @Test
    func onSelected_setsDestinationToDetail() async {
        let book = Self.makeBook()
        var state = ShelfFeature.State.make()
        state.$books.withLock { $0 = .init(uniqueElements: [book]) }

        let store = TestStore(initialState: state) {
            ShelfFeature()
        }

        await store.send(.screen(.onSelected(book))) {
            $0.destination = .detail(.make(book: Shared(state.$books[id: book.id])!))
        }
    }

    // MARK: - onAddTapped → destination が .add になる

    @Test
    func onAddTapped_setsDestinationToAdd() async {
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        }

        await store.send(.screen(.onAddTapped("search text"))) {
            $0.destination = .add(.make(text: "search text"))
        }
    }

    // MARK: - onImport → JSON読み込み＆書籍復元

    @Test
    func onImport_importsBooks() async throws {
        let book = Self.makeBook()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode([book])
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_import.json")
        try data.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let resumedBooks = LockIsolated<[Book]?>(nil)
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        } withDependencies: {
            $0[ShelfClient.self].resume = { @Sendable books in resumedBooks.setValue(books) }
        }
        store.exhaustivity = .off

        await store.send(.screen(.onImport(tempURL)))
        await store.receive(\.internal.import)
        await store.receive(\.internal.imported)
        store.state.$books.withLock { #expect($0 == .init(uniqueElements: [book])) }
        #expect(resumedBooks.value != nil)
    }

    // MARK: - destination(.dismiss) で tags の場合に selected が反映される

    @Test
    func destinationDismiss_tags_reflectsSelected() async {
        let tag = Self.makeTag()
        var state = ShelfFeature.State.make()
        state.destination = .tags(.init(tags: .init(), selected: [tag]))

        let store = TestStore(initialState: state) {
            ShelfFeature()
        }

        await store.send(.destination(.dismiss)) {
            $0.tags = [tag]
            $0.destination = nil
        }
    }

    // MARK: - items のフィルタリング（テキスト＆タグ）

    @Test
    func items_filtersByTextAndTags() {
        let tag1 = Self.makeTag(id: 0, name: "Swift")
        let tag2 = Self.makeTag(id: 1, name: "Kotlin")

        let book1 = Self.makeBook(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Swift Programming",
            tags: [tag1]
        )
        let book2 = Self.makeBook(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            title: "Kotlin Guide",
            tags: [tag2]
        )

        var state = ShelfFeature.State.make()
        state.$books.withLock { $0 = .init(uniqueElements: [book1, book2]) }

        // Filter by text
        state.text = "Swift"
        #expect(state.items.count == 1)
        #expect(state.items.first?.id == book1.id)

        // Filter by tag
        state.text = ""
        state.tags = [tag1]
        #expect(state.items.count == 1)
        #expect(state.items.first?.id == book1.id)

        // Filter by both
        state.text = "Kotlin"
        state.tags = [tag1]
        #expect(state.items.isEmpty)
    }

    // MARK: - onRefresh → 再読み込み

    @Test
    func onRefresh_reloadsBooks() async {
        let book = Self.makeBook()
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAll = { @Sendable _ in [book] }
            $0.continuousClock = ImmediateClock()
        }
        store.exhaustivity = .off

        await store.send(.screen(.onRefresh))
        await store.receive(\.books.load)
        await store.receive(\.books.loaded)
        store.state.$books.withLock { #expect($0 == .init(uniqueElements: [book])) }
    }

    // MARK: - external(.onPersistentStoreRemoteChanged) → 再読み込み

    @Test
    func onPersistentStoreRemoteChanged_reloadsBooks() async {
        let book = Self.makeBook()
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAll = { @Sendable _ in [book] }
            $0.continuousClock = ImmediateClock()
        }
        store.exhaustivity = .off

        await store.send(.external(.onPersistentStoreRemoteChanged))
        await store.receive(\.books.load)
        await store.receive(\.books.loaded)
        store.state.$books.withLock { #expect($0 == .init(uniqueElements: [book])) }
    }

    // MARK: - task で featureFlags が反映される

    @Test
    func task_setsFeatureFlags() async {
        let book = Self.makeBook()
        let store = TestStore(initialState: ShelfFeature.State.make()) {
            ShelfFeature()
        } withDependencies: {
            $0[ShelfClient.self].fetchAll = { @Sendable _ in [book] }
            $0[FeatureFlags.self].enableImport = { true }
            $0[FeatureFlags.self].enableExport = { true }
            $0.continuousClock = ImmediateClock()
        }
        store.exhaustivity = .off

        await store.send(.screen(.task)) {
            $0.enableImport = true
            $0.enableExport = true
        }
        await store.receive(\.books.load)
        await store.receive(\.books.loaded)
        store.state.$books.withLock { #expect($0 == .init(uniqueElements: [book])) }
    }
}
