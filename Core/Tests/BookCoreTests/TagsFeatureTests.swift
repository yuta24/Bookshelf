import ComposableArchitecture
import XCTest
@testable import BookCore
import BookModel
import TagClient

final class TagsFeatureTests: XCTestCase {
    let tag1 = Tag(
        id: .init(UUID(0)),
        name: "Swift",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )
    let tag2 = Tag(
        id: .init(UUID(1)),
        name: "Kotlin",
        createdAt: Date(timeIntervalSince1970: 0),
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    @MainActor
    func test_task_loadsTags() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [], selected: [])
        ) {
            TagsFeature()
        } withDependencies: {
            $0[TagClient.self].fetchAll = { [tag1, tag2] in [tag1, tag2] }
        }

        await store.send(.screen(.task))
        await store.receive(\.tags.load)
        await store.receive(\.tags.loaded) {
            $0.tags = [self.tag1, self.tag2]
        }
    }

    @MainActor
    func test_onSelected_togglesSelection() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [tag1, tag2], selected: [])
        ) {
            TagsFeature()
        }

        await store.send(.screen(.onSelected(tag1))) {
            $0.selected = [self.tag1]
        }

        await store.send(.screen(.onSelected(tag1))) {
            $0.selected = []
        }
    }

    @MainActor
    func test_addTapped_emptyText_showsEmptyEntryAlert() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [], text: "", selected: [])
        ) {
            TagsFeature()
        }

        await store.send(.screen(.add(.onAddTapped)))
        await store.receive(\.tags.registered) {
            $0.destination = .alert(.init(
                title: { .init("alert.title.empty_tag") },
                actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) }
            ))
        }
    }

    @MainActor
    func test_addTapped_duplicateTag_showsDuplicateEntryAlert() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [tag1], text: "Swift", selected: [])
        ) {
            TagsFeature()
        } withDependencies: {
            $0[TagClient.self].exists = { _ in true }
        }

        await store.send(.screen(.add(.onAddTapped)))
        await store.receive(\.tags.register)
        await store.receive(\.tags.registered) {
            $0.text = ""
            $0.destination = .alert(.init(
                title: { .init("alert.title.duplicate_tag") },
                actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) }
            ))
        }
    }

    @MainActor
    func test_addTapped_success_clearsTextAndReloads() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [tag1], text: "Kotlin", selected: [])
        ) {
            TagsFeature()
        } withDependencies: { [tag1, tag2] in
            $0[TagClient.self].exists = { _ in false }
            $0[TagClient.self].create = { _ in tag2 }
            $0[TagClient.self].fetchAll = { [tag1, tag2] }
        }

        await store.send(.screen(.add(.onAddTapped)))
        await store.receive(\.tags.register)
        await store.receive(\.tags.registered.success) {
            $0.text = ""
            $0.tags = [self.tag1, self.tag2]
        }
        await store.receive(\.tags.load)
        await store.receive(\.tags.loaded)
    }

    @MainActor
    func test_onDeleteTapped_removesTag() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [tag1, tag2], selected: [])
        ) {
            TagsFeature()
        } withDependencies: {
            $0[TagClient.self].delete = { _ in }
        }

        await store.send(.screen(.onDeleteTapped(tag1)))
        await store.receive(\.tags.remove)
        await store.receive(\.tags.removed) {
            $0.tags = [self.tag2]
        }
    }

    @MainActor
    func test_onRefresh_reloads() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [], selected: [])
        ) {
            TagsFeature()
        } withDependencies: {
            $0[TagClient.self].fetchAll = { [tag1] in [tag1] }
        }

        await store.send(.screen(.onRefresh))
        await store.receive(\.tags.load)
        await store.receive(\.tags.loaded) {
            $0.tags = [self.tag1]
        }
    }

    @MainActor
    func test_onPersistentStoreRemoteChanged_reloads() async {
        let store = TestStore(
            initialState: TagsFeature.State(tags: [], selected: [])
        ) {
            TagsFeature()
        } withDependencies: {
            $0[TagClient.self].fetchAll = { [tag1, tag2] in [tag1, tag2] }
        }

        await store.send(.external(.onPersistentStoreRemoteChanged))
        await store.receive(\.tags.load)
        await store.receive(\.tags.loaded) {
            $0.tags = [self.tag1, self.tag2]
        }
    }
}
