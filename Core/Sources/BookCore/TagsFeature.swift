public import ComposableArchitecture

public import BookModel

import Foundation
import CasePaths
import OrderedCollections
import TagClient

@Reducer
public struct TagsFeature: Sendable {
    @Reducer
    public struct Destination: Sendable {
        public enum State: Equatable, Sendable {
            case alert(AlertState<Action.AlertAction>)
        }

        public enum Action: Sendable {
            public enum AlertAction: Equatable, Sendable {
                case onCloseTapped
            }

            case alert(AlertAction)
        }

        public var body: some ReducerOf<Self> {
            Reduce { _, _ in
                .none
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public var tags: IdentifiedArrayOf<Tag>
        public var text: String = ""
        public var selected: [Tag]

        public var isAddPresented: Bool = false

        @Presents
        public var destination: Destination.State?

        public var isAddEnabled: Bool { !text.isEmpty }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum TagsAction: Sendable {
            case load
            case loaded([Tag])
            case register(CreatingTag)
            case registered(Result<[Tag], any Error>)
            case update(Tag)
            case updated(Tag)
            case remove(Tag.ID)
            case removed(Tag.ID)
        }

        @CasePathable
        public enum ScreenAction: Sendable {
            @CasePathable
            public enum AddAction: Sendable {
                case onTextChanged(String)
                case onAddTapped
                case onCancelTapped
                case onDismissed(Bool)
            }

            case add(AddAction)

            case task
            case onRefresh
            case onSelected(Tag)
            case onDeleteTapped(Tag)
            case onAddTapped
            case onCloseTapped
        }

        @CasePathable
        public enum ExternalAction: Sendable {
            case onPersistentStoreRemoteChanged
        }

        case tags(TagsAction)

        case destination(PresentationAction<Destination.Action>)
        case screen(ScreenAction)
        case external(ExternalAction)
    }

    @Dependency(\.dismiss)
    var dismiss
    @Dependency(TagClient.self)
    var tagClient

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .tags(.load):
                return .run { send in
                    let tags = try await tagClient.fetchAll()
                    await send(.tags(.loaded(tags)))
                }
            case let .tags(.loaded(tags)):
                state.tags = .init(uniqueElements: tags)
                return .none
            case let .tags(.register(item)):
                return .run { send in
                    let exists = try await tagClient.exists(item.name)
                    if !exists {
                        _ = try await tagClient.create(item)
                        let tags = try await tagClient.fetchAll()
                        await send(.tags(.registered(.success(tags))))
                    } else {
                        await send(.tags(.registered(.failure(DuplicateEntry()))))
                    }
                }
            case let .tags(.registered(.success(tags))):
                state.text = ""
                state.tags = .init(uniqueElements: tags)
                return .send(.tags(.load))
            case let .tags(.registered(.failure(error))):
                state.text = ""

                switch error {
                case is DuplicateEntry:
                    state.destination = .alert(.init(
                        title: { .init("alert.title.duplicate_tag") },
                        actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) }
                    ))
                case is EmptyEntry:
                    state.destination = .alert(.init(
                        title: { .init("alert.title.empty_tag") },
                        actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) }
                    ))
                default:
                    break
                }

                return .none
            case let .tags(.update(tag)):
                return .run { send in
                    let tag = try await tagClient.update(tag)
                    await send(.tags(.update(tag)))
                }
            case let .tags(.updated(tag)):
                state.tags[id: tag.id] = tag
                return .none
            case let .tags(.remove(id)):
                return .run { send in
                    try await tagClient.delete(id)
                    await send(.tags(.removed(id)))
                }
            case let .tags(.removed(id)):
                state.tags.remove(id: id)
                return .none
            case .destination(.presented(.alert(.onCloseTapped))):
                state.destination = nil
                return .none
            case .destination:
                return .none
            case .tags:
                return .none
            case let .screen(.add(.onTextChanged(text))):
                state.text = text
                return .none
            case .screen(.add(.onAddTapped)):
                if !state.text.isEmpty {
                    return .send(.tags(.register(.init(name: state.text))))
                } else {
                    return .send(.tags(.registered(.failure(EmptyEntry()))))
                }
            case .screen(.add(.onCancelTapped)):
                state.isAddPresented = false
                return .none
            case let .screen(.add(.onDismissed(isPresented))):
                state.isAddPresented = isPresented
                return .none
            case .screen(.task):
                return .send(.tags(.load))
            case .screen(.onRefresh):
                return .send(.tags(.load))
            case let .screen(.onSelected(tag)):
                if state.selected.contains(tag) {
                    state.selected.removeAll(where: { $0.id == tag.id })
                } else {
                    state.selected.append(tag)
                }

                return .none
            case let .screen(.onDeleteTapped(tag)):
                return .send(.tags(.remove(tag.id)))
            case .screen(.onAddTapped):
                state.isAddPresented = true
                return .none
            case .screen(.onCloseTapped):
                return .run { _ in
                    await dismiss()
                }
            case .external(.onPersistentStoreRemoteChanged):
                return .send(.tags(.load))
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
