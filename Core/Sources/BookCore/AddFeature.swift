public import Foundation

public import ComposableArchitecture

public import BookModel

import CasePaths
import Updater
import WidgetUpdater
import AnalyticsClient
import SearchClient
import ShelfClient

@Reducer
public struct AddFeature: Sendable {
    @Reducer
    public struct Destination: Sendable {
        public enum State: Equatable, Sendable {
            case scan(ScanFeature.State)
            case alert(AlertState<Action.AlertAction>)
        }

        @CasePathable
        public enum Action: Sendable {
            @CasePathable
            public enum AlertAction: Equatable, Sendable {
                case onCloseTapped
            }

            case scan(ScanFeature.Action)
            case alert(AlertAction)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.scan, action: \.scan) {
                ScanFeature()
            }
        }
    }

    public struct Item: Identifiable, Equatable, Sendable {
        public let book: SearchingBook
        public var selected: Bool = false

        public var id: String {
            book.id
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public let upper: Int = 10

        @Shared(.books)
        public var books: IdentifiedArrayOf<Book> = []

        public var text: String = ""
        public var picks: IdentifiedArrayOf<SearchingBook> = []
        public var items: IdentifiedArrayOf<Item> = []

        @Presents
        public var destination: Destination.State?

        public var isCustomActived: Bool = false

        public var canAddToPicks: Bool {
            picks.count < upper
        }

        public var isRegisterEnabled: Bool {
            !picks.isEmpty
        }

        public static func make(text: String = "") -> State {
            .init(text: text)
        }

        mutating func select(book: SearchingBook) {
            items[id: book.id]?.selected = true
            picks.append(book)
        }

        mutating func deselect(book: SearchingBook) {
            items[id: book.id]?.selected = false
            picks.remove(id: book.id)
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum BooksAction: Sendable {
            case register(IdentifiedArrayOf<SearchingBook>)
            case registered(Result<[Book], any Error>)
        }

        @CasePathable
        public enum ScreenAction: Sendable {
            case task
            case textChanged(String)
            case onSelected(SearchingBook)
            case onSubmitted
            case onClearTapped
            case onCameraTapped
            case onRegisterTapped
            case onCustomTapped
            case onCustomDismissed(Bool)
            case onDelete(SearchingBook)
            case onCloseTapped
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case update
            case updated([SearchingBook], HTTPURLResponse)
            case failed(any Error)
        }

        case books(BooksAction)
        case destination(PresentationAction<Destination.Action>)
        case screen(ScreenAction)
        case `internal`(InternalAction)
    }

    @Dependency(AnalyticsClient.self)
    var analyticsClient
    @Dependency(SearchClient.self)
    var searchClient
    @Dependency(ShelfClient.self)
    var shelfClient
    @Dependency(WidgetUpdater.self)
    var widgetUpdater
    @Dependency(\.continuousClock)
    var clock
    @Dependency(\.dismiss)
    var dismiss

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            enum CancelID { case update }

            switch action {
            case let .books(.register(books)):
                return .run { send in
                    let books: [Book] = try await {
                        var news: [Book] = []
                        for book in books {
                            try await news.append(shelfClient.create(book))
                        }
                        return news
                    }()

                    await send(.books(.registered(.success(books))))
                } catch: { _, send in
                    await send(.books(.registered(.failure(DuplicateEntry()))))
                }
            case let .books(.registered(.success(books))):
                state.$books.withLock { $0.insert(contentsOf: books.reversed(), at: 0) }
                return .run { _ in
                    analyticsClient.log(event: .books(.registered(count: books.count)))
                    await widgetUpdater.setNeedNotify()
                    await dismiss()
                }
            case .books(.registered(.failure)):
                state.destination = .alert(.init(
                    title: { .init("alert.title.duplicate_book") },
                    actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) }
                ))
                return .none
            case let .destination(.presented(.scan(.delegate(.register(book))))):
                return .send(.books(.register([book])))
            case .destination(.presented(.alert(.onCloseTapped))):
                state.destination = nil
                return .none
            case .destination:
                return .none
            case .screen(.task):
                if ProcessInfo.processInfo.arguments.contains("snapshot") {
                    state.text = "情報設計"
                    return .send(.internal(.update))
                } else if !state.text.isEmpty {
                    return .send(.internal(.update))
                } else {
                    return .none
                }
            case let .screen(.textChanged(text)):
                state.text = text
                return .none
            case let .screen(.onSelected(book)):
                guard let registered = book.registered, !registered else { return .none }

                if state.picks.ids.contains(book.id) {
                    state.deselect(book: book)
                    return .none
                } else {
                    if state.canAddToPicks {
                        state.select(book: book)
                    } else {
                        state.destination = .alert(.init(
                            title: { .init("alert.title.registration_limit_reached") },
                            actions: { .init(action: .onCloseTapped, label: { .init("button.title.close") }) },
                            message: { [upper = state.upper] in
                                .init("alert.message.registration_limit: \(upper)")
                            }
                        ))
                    }
                    return .none
                }
            case .screen(.onSubmitted):
                return .send(.internal(.update))
            case .screen(.onClearTapped):
                state.text = ""
                state.items = []
                return .none
            case .screen(.onCameraTapped):
                state.destination = .scan(.init())
                return .none
            case .screen(.onRegisterTapped):
                return .send(.books(.register(state.picks)))
            case .screen(.onCustomTapped):
                state.isCustomActived = true
                return .none
            case let .screen(.onCustomDismissed(isActived)):
                state.isCustomActived = isActived
                return .none
            case let .screen(.onDelete(book)):
                state.deselect(book: book)
                if state.picks.isEmpty {
                    state.isCustomActived = false
                }
                return .none
            case .screen(.onCloseTapped):
                return .run { _ in
                    await dismiss()
                }
            case .internal(.update):
                let text = state.text
                return .run { send in
                    try await clock.sleep(for: .seconds(1))
                    let (books, response) = try await searchClient.search(.title(text))

                    let exists: [String: Bool] = try await {
                        var exists: [String: Bool] = [:]

                        for book in books {
                            exists[book.isbn] = try await shelfClient.exists(.init(book.isbn))
                        }

                        return exists
                    }()

                    let books_ = books.map { (Updater($0), $0) }
                        .map { $0.update(exists[$1.isbn], \.registered) }
                        .map(\.value)

                    await send(.internal(.updated(books_, response)))
                } catch: { error, send in
                    await send(.internal(.failed(error)))
                }
                .cancellable(id: CancelID.update, cancelInFlight: true)
            case let .internal(.updated(books, response)):
                if !(200 ..< 400).contains(response.statusCode) {
                    state.destination = .alert(
                        AlertHelper.alert(from: response, action: .onCloseTapped)
                    )
                } else {
                    state.items = .init(uniqueElements: books.map { Item(book: $0) })
                }

                return .none
            case let .internal(.failed(error)):
                state.destination = .alert(
                    AlertHelper.alert(from: error, action: .onCloseTapped)
                )
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
