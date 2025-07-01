public import ComposableArchitecture

public import Tagged

public import BookModel

import Foundation
import CasePaths
import ShelfClient
import TagClient

@Reducer
public struct EditTagFeature: Sendable {
    public struct Item: Identifiable, Equatable, Sendable {
        public var tag: Tag
        public var selected: Bool

        public var id: Tag.ID { tag.id }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared
        public var book: Book
        public var items: IdentifiedArrayOf<Item>
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum BooksAction: Sendable {
            case update(Book)
            case updated(Book)
        }

        @CasePathable
        public enum ScreenAction: Sendable {
            case task
            case onSelected(Item)
            case onCloseTapped
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case fetch
            case fetched([Tag])
        }

        case books(BooksAction)
        case screen(ScreenAction)
        case `internal`(InternalAction)
    }

    @Dependency(\.dismiss)
    var dismiss
    @Dependency(ShelfClient.self)
    var shelfClient
    @Dependency(TagClient.self)
    var tagClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .books(.update(book)):
                return .run { send in
                    let book = try await shelfClient.update(book)
                    await send(.books(.updated(book)))
                }
            case .books(.updated):
                return .none
            case .screen(.task):
                return .send(.internal(.fetch))
            case let .screen(.onSelected(item)):
                if item.selected {
                    state.items[id: item.id]?.selected = false
                } else {
                    state.items[id: item.id]?.selected = true
                }

                if state.book.tags.contains(item.tag) {
                    state.$book.withLock { $0.tags.removeAll { $0.id == item.tag.id } }
                } else {
                    state.$book.withLock {
                        $0.tags.append(item.tag)
                        $0.tags.sort(by: { $0.name < $1.name })
                    }
                }

                return .send(.books(.update(state.book)))
            case .screen(.onCloseTapped):
                return .run { _ in
                    await dismiss()
                }
            case .internal(.fetch):
                return .run { send in
                    let tags = try await tagClient.fetchAll()
                    await send(.internal(.fetched(tags)))
                }
            case let .internal(.fetched(tags)):
                state.items = .init(uniqueElements: tags.map { tag in
                    Item(tag: tag, selected: state.book.tags.contains(tag))
                })
                return .none
            }
        }
    }
}
