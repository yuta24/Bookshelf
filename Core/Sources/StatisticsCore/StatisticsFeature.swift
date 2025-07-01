public import Foundation

public import ComposableArchitecture

public import OrderedCollections

public import BookModel

import CasePaths
import ShelfClient

private let calendar = Calendar(identifier: .gregorian)

@Reducer
public struct StatisticsFeature: Sendable {
    public enum Tab: Equatable, CaseIterable, Sendable {
        case yearly
        case insight
    }

    public struct Custom: Equatable, Sendable {
        public enum Target: Equatable, CaseIterable, Sendable {
            case created
            case read
        }

        public var target: Target
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public var tab: Tab = .yearly
        public var latest: Date = .init()
        public var select: Date?
        public var books: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = .init()
        public var custom: Custom = .init(target: .created)

        public var current: Date {
            select ?? latest
        }

        public var previousEnabled: Bool {
            true
        }

        public var nextEnabled: Bool {
            if let select {
                let latestYear = calendar.component(.year, from: latest)
                let selectYear = calendar.component(.year, from: select)
                return selectYear < latestYear
            } else {
                return false
            }
        }

        public static func make() -> State {
            .init()
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            public enum Custom: Sendable {
                case onTargetSelected(StatisticsFeature.Custom.Target)
            }

            case custom(Custom)
            case onAppear
            case tabChanged(Tab)
            case onPreviousTapped
            case onNextTapped
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case fetched([Book])
        }

        @CasePathable
        public enum ExternalAction: Sendable {
            case onActive
        }

        case screen(ScreenAction)
        case `internal`(InternalAction)
        case external(ExternalAction)
    }

    @Dependency(ShelfClient.self)
    var shelfClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            func from(_ book: Book, by target: StatisticsFeature.Custom.Target) -> Date? {
                switch target {
                case .created:
                    book.createdAt
                case .read:
                    book.status.readAt
                }
            }

            switch action {
            case let .screen(.custom(.onTargetSelected(target))):
                state.custom.target = target
                return .send(.screen(.onAppear))
            case .screen(.onAppear):
                let year = calendar.component(.year, from: state.current)
                return .run { send in
                    let books = try await shelfClient.fetchAtYear(year)
                    await send(.internal(.fetched(books)))
                }
            case let .screen(.tabChanged(tab)):
                state.tab = tab
                return .none
            case .screen(.onPreviousTapped):
                state.select = calendar.date(byAdding: .init(year: -1), to: state.current)
                let year = calendar.component(.year, from: state.current)
                return .run { send in
                    let books = try await shelfClient.fetchAtYear(year)
                    await send(.internal(.fetched(books)))
                }
            case .screen(.onNextTapped):
                state.select = calendar.date(byAdding: .init(year: 1), to: state.current)
                let year = calendar.component(.year, from: state.current)
                return .run { send in
                    let books = try await shelfClient.fetchAtYear(year)
                    await send(.internal(.fetched(books)))
                }
            case let .internal(.fetched(books)):
                var ordered: OrderedDictionary<Int, IdentifiedArrayOf<Book>> = [:]

                for index in 1 ... 12 {
                    ordered[index] = []
                }

                for book in books {
                    if let date = from(book, by: state.custom.target) {
                        let month = calendar.component(.month, from: date)
                        ordered[month]?.append(book)
                    }
                }

                state.books = ordered

                return .none
            case .external(.onActive):
                state.latest = .init()
                let year = calendar.component(.year, from: state.current)
                return .run { send in
                    let books = try await shelfClient.fetchAtYear(year)
                    await send(.internal(.fetched(books)))
                }
            }
        }
    }
}
