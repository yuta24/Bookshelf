public import Foundation

public import ComposableArchitecture

public import BookModel

public import GenreModel

import CasePaths
import Updater
import AnalyticsClient
import BookClient
import GenreClient
import ShelfClient

@Reducer
public struct BooksFeature: Sendable {
    @Reducer
    public struct Destination: Sendable {
        public enum State: Equatable, Sendable {
            case book(BookFeature.State)
            case alert(AlertState<Action.AlertAction>)
        }

        @CasePathable
        public enum Action: Sendable {
            @CasePathable
            public enum AlertAction: Equatable, Sendable {
                case onCloseTapped
            }

            case book(BookFeature.Action)
            case alert(AlertAction)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.book, action: \.book) {
                BookFeature()
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public var genres: IdentifiedArrayOf<Genre>
        public var news: IdentifiedArrayOf<SearchingBook>
        public var sales: IdentifiedArrayOf<SearchingBook>
        @Shared(.genre)
        public var genre: Genre = .init(id: .init("001001"), name: "漫画（コミック）")

        @Presents
        public var destination: Destination.State?

        public static func make() -> State {
            .init(
                genres: [],
                news: [],
                sales: []
            )
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            case task
            case onRefresh
            case genreSelected(Genre)
            case onBookTapped(SearchingBook)
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case fetch
            case fetched(Result<([Genre], [SearchingBook], HTTPURLResponse, [SearchingBook], HTTPURLResponse), any Error>)
        }

        case destination(PresentationAction<Destination.Action>)
        case screen(ScreenAction)
        case `internal`(InternalAction)
    }

    @Dependency(BookClient.self)
    var bookClient
    @Dependency(GenreClient.self)
    var genreClient
    @Dependency(ShelfClient.self)
    var shelfClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination(.presented(.alert(.onCloseTapped))):
                state.destination = nil
                return .none
            case .destination(.dismiss):
                state.destination = nil
                return .none
            case .destination:
                return .none
            case .screen(.task):
                return .send(.internal(.fetch))
            case .screen(.onRefresh):
                return .send(.internal(.fetch))
            case let .screen(.genreSelected(genre)):
                state.$genre.withLock { $0 = genre }
                return .run { send in
                    await send(.internal(.fetch))
                }
            case let .screen(.onBookTapped(book)):
                state.destination = .book(.make(book: book))
                return .none
            case .internal(.fetch):
                return .run { [genre = state.genre] send in
                    let genres = try await genreClient.fetch()
                    let (news, response1) = try await fetch(genre: genre, kind: .new)
                    let (sales, response2) = try await fetch(genre: genre, kind: .sales)
                    await send(.internal(.fetched(.success((genres, news, response1, sales, response2)))))
                } catch: { error, send in
                    await send(.internal(.fetched(.failure(error))))
                }
            case let .internal(.fetched(.success((genres, news, response1, sales, response2)))):
                if !(200 ..< 400).contains(response1.statusCode) {
                    state.destination = .alert(
                        AlertHelper.alert(from: response1, action: .onCloseTapped)
                    )
                } else if !(200 ..< 400).contains(response2.statusCode) {
                    state.destination = .alert(
                        AlertHelper.alert(from: response2, action: .onCloseTapped)
                    )
                } else {
                    state.genres = .init(uniqueElements: genres)
                    state.news = .init(uniqueElements: news)
                    state.sales = .init(uniqueElements: sales)
                }
                return .none
            case let .internal(.fetched(.failure(error))):
                state.destination = .alert(
                    AlertHelper.alert(from: error, action: .onCloseTapped)
                )
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }

    private func fetch(genre: Genre, kind: BookClient.Kind) async throws -> ([SearchingBook], HTTPURLResponse) {
        let (books, response) = try await bookClient.fetch(genre: genre, kind: kind)

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

        return (books_, response)
    }
}
