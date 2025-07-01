public import ComposableArchitecture

public import BookModel

import Foundation
import CasePaths
import WidgetUpdater
import AnalyticsClient
import ShelfClient

@Reducer
public struct BookFeature: Sendable {
    @Reducer
    public struct Destination: Sendable {
        public enum State: Equatable, Sendable {
            case alert(AlertState<Action.AlertAction>)
        }

        @CasePathable
        public enum Action: Sendable {
            @CasePathable
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
        @Shared(.books)
        public var books: IdentifiedArrayOf<Book> = []
        public var book: SearchingBook

        @Presents
        public var destination: Destination.State?

        public static func make(book: SearchingBook) -> State {
            .init(book: book)
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum BooksAction: Sendable {
            case register
            case registered(Result<Book, any Error>)
        }

        @CasePathable
        public enum ScreenAction: Sendable {
            case onRegisterTapped
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case registered(Int)
        }

        case books(BooksAction)

        case destination(PresentationAction<Destination.Action>)
        case screen(ScreenAction)
        case `internal`(InternalAction)
    }

    @Dependency(WidgetUpdater.self)
    var widgetUpdater
    @Dependency(AnalyticsClient.self)
    var analyticsClient
    @Dependency(ShelfClient.self)
    var shelfClient
    @Dependency(\.dismiss)
    var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            let mutator = { @Sendable (closure: () -> Action) async -> Action in
                await widgetUpdater.setNeedNotify()
                return closure()
            }

            switch action {
            case .books(.register):
                return .run { [book = state.book] send in
                    let exists = try await shelfClient.exists(.init(rawValue: book.isbn))
                    if !exists {
                        let book = try await shelfClient.create(book)
                        await send(mutator { .books(.registered(.success(book))) })
                    } else {
                        await send(.books(.registered(.failure(DuplicateEntry()))))
                    }
                } catch: { _, _ in
                    // TODO: error handling
                }
            case let .books(.registered(.success(book))):
                state.$books.withLock { $0.insert(book, at: 0) }
                return .run { _ in
                    await dismiss()
                }
            case .books(.registered(.failure)):
                state.destination = .alert(
                    .init(
                        title: { .init("alert.title.duplicate_book") },
                        actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) }
                    ))
                return .none
            case .destination(.presented(.alert(.onCloseTapped))):
                state.destination = nil
                return .run { _ in
                    await dismiss()
                }
            case .destination:
                return .none
            case .screen(.onRegisterTapped):
                return .send(.books(.register))
            case let .internal(.registered(count)):
                analyticsClient.log(event: .books(.registered(count: count)))
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
