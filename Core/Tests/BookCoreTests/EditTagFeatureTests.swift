import ComposableArchitecture
import XCTest
@testable import BookCore
import BookModel
import ShelfClient
import TagClient

final class EditTagFeatureTests: XCTestCase {
    let tag1 = Tag(
        id: .init(UUID(0)),
        name: "Kotlin",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )
    let tag2 = Tag(
        id: .init(UUID(1)),
        name: "Swift",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    func makeBook(tags: [Tag] = []) -> Book {
        Book(
            id: .init(UUID(2)),
            title: .init(rawValue: "Test Book"),
            author: .init(rawValue: "Author"),
            price: .init(rawValue: 1000),
            affiliateURL: nil,
            imageURL: URL(string: "https://example.com/image.png")!,
            isbn: .init(rawValue: "9784000000000"),
            publisher: .init(rawValue: "Publisher"),
            caption: nil,
            salesAt: .init(rawValue: "2025年01月01日"),
            bought: false,
            note: .init(rawValue: ""),
            status: .unread,
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            tags: tags
        )
    }

    // MARK: - task → fetch tags

    @MainActor
    func test_task_fetchesTags_andSetsItems() async {
        let book = makeBook()
        @Shared(.inMemory("editTagTest1")) var sharedBook = book

        let store = TestStore(
            initialState: EditTagFeature.State(book: $sharedBook, items: [])
        ) {
            EditTagFeature()
        } withDependencies: { [tag1, tag2] in
            $0[TagClient.self].fetchAll = { [tag1, tag2] }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.items = [
                EditTagFeature.Item(tag: self.tag1, selected: false),
                EditTagFeature.Item(tag: self.tag2, selected: false),
            ]
        }
    }

    @MainActor
    func test_task_fetchesTags_withPreselected() async {
        let book = makeBook(tags: [tag2])
        @Shared(.inMemory("editTagTest2")) var sharedBook = book

        let store = TestStore(
            initialState: EditTagFeature.State(book: $sharedBook, items: [])
        ) {
            EditTagFeature()
        } withDependencies: { [tag1, tag2] in
            $0[TagClient.self].fetchAll = { [tag1, tag2] }
        }

        await store.send(.screen(.task))
        await store.receive(\.internal.fetch)
        await store.receive(\.internal.fetched) {
            $0.items = [
                EditTagFeature.Item(tag: self.tag1, selected: false),
                EditTagFeature.Item(tag: self.tag2, selected: true),
            ]
        }
    }

    // MARK: - onSelected: select a tag

    @MainActor
    func test_onSelected_selectsTag_andUpdatesBook() async {
        let book = makeBook()
        @Shared(.inMemory("editTagTest3")) var sharedBook = book

        let item = EditTagFeature.Item(tag: tag1, selected: false)

        let store = TestStore(
            initialState: EditTagFeature.State(
                book: $sharedBook,
                items: [
                    EditTagFeature.Item(tag: tag1, selected: false),
                    EditTagFeature.Item(tag: tag2, selected: false),
                ]
            )
        ) {
            EditTagFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { $0 }
        }

        await store.send(.screen(.onSelected(item))) {
            $0.items[id: self.tag1.id]?.selected = true
            $0.$book.withLock { $0.tags = [self.tag1] }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - onSelected: deselect a tag

    @MainActor
    func test_onSelected_deselectsTag_andUpdatesBook() async {
        let book = makeBook(tags: [tag1])
        @Shared(.inMemory("editTagTest4")) var sharedBook = book

        let item = EditTagFeature.Item(tag: tag1, selected: true)

        let store = TestStore(
            initialState: EditTagFeature.State(
                book: $sharedBook,
                items: [
                    EditTagFeature.Item(tag: tag1, selected: true),
                    EditTagFeature.Item(tag: tag2, selected: false),
                ]
            )
        ) {
            EditTagFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { $0 }
        }

        await store.send(.screen(.onSelected(item))) {
            $0.items[id: self.tag1.id]?.selected = false
            $0.$book.withLock { $0.tags = [] }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }

    // MARK: - Tags sorted by name

    @MainActor
    func test_onSelected_tagsAreSortedByName() async {
        // tag2 ("Swift") is added first, then tag1 ("Kotlin") — result should be sorted: Kotlin, Swift
        let book = makeBook()
        @Shared(.inMemory("editTagTest5")) var sharedBook = book

        let itemSwift = EditTagFeature.Item(tag: tag2, selected: false)
        let itemKotlin = EditTagFeature.Item(tag: tag1, selected: false)

        let store = TestStore(
            initialState: EditTagFeature.State(
                book: $sharedBook,
                items: [
                    EditTagFeature.Item(tag: tag1, selected: false),
                    EditTagFeature.Item(tag: tag2, selected: false),
                ]
            )
        ) {
            EditTagFeature()
        } withDependencies: {
            $0[ShelfClient.self].update = { $0 }
        }

        // Select Swift first
        await store.send(.screen(.onSelected(itemSwift))) {
            $0.items[id: self.tag2.id]?.selected = true
            $0.$book.withLock { $0.tags = [self.tag2] }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)

        // Select Kotlin — tags should be sorted: [Kotlin, Swift]
        await store.send(.screen(.onSelected(itemKotlin))) {
            $0.items[id: self.tag1.id]?.selected = true
            $0.$book.withLock { $0.tags = [self.tag1, self.tag2] }
        }
        await store.receive(\.books.update)
        await store.receive(\.books.updated)
    }
}
