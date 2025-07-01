import Foundation
import CasePaths
import ComposableArchitecture
import FeatureFlags
import BookCore
import SettingsCore
import StatisticsCore

@Reducer
struct TopFeature {
    enum Tab {
        case shelf
        case books
        case statistics
        case settings
    }

    @ObservableState
    struct State: Equatable, Sendable {
        var shelf: ShelfFeature.State
        var books: BooksFeature.State
        var statistics: StatisticsFeature.State
        var settings: SettingsFeature.State
        var enableBooks: Bool = false

        var selected: Tab = .shelf

        static func make(groupID: String) -> State {
            .init(
                shelf: .make(),
                books: .make(),
                statistics: .make(),
                settings: .make(isSyncEnabled: false, groupID: groupID)
            )
        }
    }

    @CasePathable
    enum Action: Sendable {
        @CasePathable
        enum ScreenAction: Sendable {
            case onLoad
            case tabChanged(Tab)
        }

        case shelf(ShelfFeature.Action)
        case books(BooksFeature.Action)
        case statistics(StatisticsFeature.Action)
        case settings(SettingsFeature.Action)

        case screen(ScreenAction)
    }

    @Dependency(FeatureFlags.self)
    var featureFlags

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .shelf:
                return .none
            case .books:
                return .none
            case .statistics:
                return .none
            case .settings:
                return .none
            case .screen(.onLoad):
                state.enableBooks = featureFlags.enableBooks()
                return .none
            case let .screen(.tabChanged(tab)):
                if state.selected == tab {
                    switch tab {
                    case .shelf:
                        state.shelf.destination = nil
                    case .books:
                        break
                    case .statistics:
                        break
                    case .settings:
                        break
                    }
                    state.selected = tab
                    return .none
                } else {
                    state.selected = tab
                    return .none
                }
            }
        }

        Scope(state: \.shelf, action: \.shelf) {
            ShelfFeature()
        }
        Scope(state: \.books, action: \.books) {
            BooksFeature()
        }
        Scope(state: \.statistics, action: \.statistics) {
            StatisticsFeature()
        }
        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }
    }
}
