import SwiftUI
import ComposableArchitecture
import WidgetUpdater
import HotComponent

@Reducer
struct RootFeature {
    @ObservableState
    struct State: Equatable, Sendable {
        var top: TopFeature.State
    }

    enum Action: Sendable {
        enum ScreenAction: Sendable {
            case onLoad
            case onChange(ScenePhase)
        }

        case top(TopFeature.Action)

        case screen(ScreenAction)
    }

    @Dependency(WidgetUpdater.self)
    var widgetUpdater

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .top:
                return .none
            case .screen(.onLoad):
                setupComponent()
                return .none
            case let .screen(.onChange(phase)):
                switch phase {
                case .background:
                    break
                case .inactive:
                    return .run { _ in
                        await widgetUpdater.notifyIfNeed()
                    }
                case .active:
                    break
                @unknown default:
                    break
                }
                return .none
            }
        }

        Scope(state: \.top, action: \.top) {
            TopFeature()
        }
    }

    private func setupComponent() {
//        ComponentContainer.default.registry.register(payload: BookGrid.ItemContent.Payload.self, for: .init(rawValue: "bookgrid.item_content"))
//
        // #if targetEnvironment(simulator)
//        let url = URL(string: "/Users/yuta24/ghq/github.com/yuta24/Bookshelf/Presentation/Sources/Presentation/Resource/Hot.json")!
//        ComponentContainer.default.observe(with: url)
        // #else
//        let url = Bundle.module.url(forResource: "Hot", withExtension: "json")!
//        ComponentContainer.default.load(with: url)
        // #endif
    }
}
