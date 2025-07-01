public import Foundation

public import ComposableArchitecture

public import BookModel

import CasePaths
import FeatureFlags
import AnalyticsClient
import ShelfClient

@Reducer
public struct ShelfFeature: Sendable {
    @Reducer
    public struct Destination: Sendable {
        @ObservableState
        public enum State: Equatable, Sendable {
            case add(AddFeature.State)
            case detail(DetailFeature.State)
            case tags(TagsFeature.State)
        }

        @CasePathable
        public enum Action: Sendable {
            case add(AddFeature.Action)
            case detail(DetailFeature.Action)
            case tags(TagsFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.add, action: \.add) {
                AddFeature()
            }
            Scope(state: \.detail, action: \.detail) {
                DetailFeature()
            }
            Scope(state: \.tags, action: \.tags) {
                TagsFeature()
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        @Shared(.books)
        public var books: IdentifiedArrayOf<Book> = []

        public var text: String = ""
        @Shared(.layout)
        public var layout: Layout = .list
        public var tags: [Tag] = []

        public var enableImport: Bool = false
        public var enableExport: Bool = false

        @Presents
        public var destination: Destination.State?

        public var items: [Book] {
            books
                .filter { book in tags.allSatisfy { tag in book.tags.contains(tag) } }
                .filter { $0.title.contains(text) || $0.author.contains(text) || $0.note.contains(text) }
        }

        public static func make(books: IdentifiedArrayOf<Book> = [], layout: Layout = .list) -> State {
            .init(books: books, layout: layout)
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum BooksAction: Sendable {
            case load
            case loaded([Book])
        }

        @CasePathable
        public enum ScreenAction: Sendable {
            case task
            case onLayoutChanged(Layout)
            case onTextChanged(String)
            case onRefresh
            case onSelected(Book)
            case onAddTapped(String)
            case onAdded
            case onTagTapped(Tag)
            case onTagsTapped
            case onImport(URL)
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case `import`(URL)
            case imported(Result<[Book], any Error>)
        }

        @CasePathable
        public enum ExternalAction: Sendable {
            case onPersistentStoreRemoteChanged
        }

        case books(BooksAction)
        case destination(PresentationAction<Destination.Action>)
        case screen(ScreenAction)
        case `internal`(InternalAction)
        case external(ExternalAction)
    }

    @Dependency(AnalyticsClient.self)
    var analyticsClient
    @Dependency(ShelfClient.self)
    var shelfClient
    @Dependency(\.continuousClock)
    var clock
    @Dependency(FeatureFlags.self)
    var featureFlags

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            enum CancelID { case load }

            switch action {
            case .books(.load):
                return .run { send in
                    try await clock.sleep(for: .seconds(0.2))
                    let books = try await shelfClient.fetchAll(nil)
                    await send(.books(.loaded(books)))
                }
                .cancellable(id: CancelID.load, cancelInFlight: true)
            case let .books(.loaded(books)):
                state.$books.withLock { $0 = .init(uniqueElements: books) }
                return .none
            case .destination(.dismiss):
                switch state.destination {
                case .some(.add):
                    break
                case .some(.detail):
                    break
                case let .some(.tags(child)):
                    state.tags = child.selected.sorted(by: { $0.name < $1.name })
                case .none:
                    break
                }

                state.destination = nil

                return .none
            case .destination:
                return .none
            case .screen(.task):
                state.enableImport = featureFlags.enableImport()
                state.enableExport = featureFlags.enableExport()
                return .send(.books(.load))
            case let .screen(.onLayoutChanged(layout)):
                state.$layout.withLock { $0 = layout }
                return .none
            case let .screen(.onTextChanged(text)):
                state.text = text
                return .none
            case .screen(.onRefresh):
                return .send(.books(.load))
            case let .screen(.onSelected(book)):
                guard let book = Shared(state.$books[id: book.id]) else { return .none }
                state.destination = .detail(.make(book: book))
                return .none
            case let .screen(.onAddTapped(text)):
                state.destination = .add(.make(text: text))
                return .none
            case .screen(.onAdded):
                return .none
            case let .screen(.onTagTapped(tag)):
                state.tags.removeAll(where: { $0.id == tag.id })
                return .none
            case .screen(.onTagsTapped):
                state.destination = .tags(.init(tags: .init(), selected: state.tags))
                return .none
            case let .screen(.onImport(url)):
                return .send(.internal(.import(url)))
            case let .internal(.import(url)):
                return .run { send in
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    let decoder: JSONDecoder = {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        return decoder
                    }()
                    let data = try Data(contentsOf: url)
                    let books = try decoder.decode([Book].self, from: data)

                    try await shelfClient.resume(books)

                    await send(.internal(.imported(.success(books))))
                } catch: { error, send in
                    await send(.internal(.imported(.failure(error))))
                }
            case let .internal(.imported(.success(books))):
                state.$books.withLock { $0 = .init(uniqueElements: books) }
                return .none
            case .internal(.imported(.failure)):
                return .none
            case .external(.onPersistentStoreRemoteChanged):
                return .send(.books(.load))
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
