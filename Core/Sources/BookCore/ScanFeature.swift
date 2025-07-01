public import Foundation

public import ComposableArchitecture

public import BookModel

import CasePaths
import SearchClient

@Reducer
public struct ScanFeature: Sendable {
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
        public var text: String = ""
        public var item: SearchingBook?

        public var requesting: Bool = false

        @Presents
        public var destination: Destination.State?
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            case captureChanged(String)
            case onSelected(SearchingBook)
            case onRescanTapped
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case update
            case updated(([SearchingBook], HTTPURLResponse))
            case failed(any Error)
        }

        @CasePathable
        public enum DelegateAction: Sendable {
            case register(SearchingBook)
        }

        case destination(PresentationAction<Destination.Action>)
        case screen(ScreenAction)
        case `internal`(InternalAction)
        case delegate(DelegateAction)
    }

    @Dependency(SearchClient.self)
    var searchClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            enum CancelID { case update }

            switch action {
            case .destination(.presented(.alert(.onCloseTapped))):
                state.requesting = false
                state.text = ""
                state.destination = nil
                return .none
            case .destination:
                return .none
            case let .screen(.captureChanged(text)):
                guard text.starts(with: "978") else { return .none }
                guard state.item == nil, state.text != text else { return .none }
                state.text = text
                return .send(.internal(.update))
            case let .screen(.onSelected(book)):
                return .send(.delegate(.register(book)))
            case .screen(.onRescanTapped):
                state.item = nil
                state.text = ""
                return .none
            case .internal(.update):
                guard !state.requesting else { return .none }
                state.requesting = true
                let text = state.text
                return .run { send in
                    let result = try await searchClient.search(.isbn(text))
                    await send(.internal(.updated(result)))
                } catch: { error, send in
                    await send(.internal(.failed(error)))
                }
                .cancellable(id: CancelID.update, cancelInFlight: true)
            case let .internal(.updated(result)):
                let (items, response) = result

                state.requesting = false

                if (200 ..< 400).contains(response.statusCode) {
                    if let item = items.first {
                        state.item = item
                    } else {
                        state.destination = .alert(.init(
                            title: { .init("alert.title.not_found_book") },
                            actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) },
                            message: { .init("alert.message.not_found_book") }
                        )
                        )
                    }
                } else {
                    state.destination = .alert(AlertHelper.alert(from: response, action: .onCloseTapped))
                }

                return .none
            case let .internal(.failed(error)):
                state.destination = .alert(AlertHelper.alert(from: error, action: .onCloseTapped))
                return .none
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
