import SwiftUI
import ComposableArchitecture
import Inject

struct TopScreen: View {
    @Bindable
    var store: StoreOf<TopFeature>

    @ObserveInjection
    var inject

    var body: some View {
        TabView(selection: $store.selected.sending(\.screen.tabChanged)) {
            ShelfScreen(store: store.scope(state: \.shelf, action: \.shelf))
                .tag(TopFeature.Tab.shelf)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("screen.title.shelf")
                }

            if store.enableBooks {
                BooksScreen(store: store.scope(state: \.books, action: \.books))
                    .tag(TopFeature.Tab.books)
                    .tabItem {
                        Image(systemName: "book")
                        Text("screen.title.books")
                    }
            }

            StatisticsScreen(store: store.scope(state: \.statistics, action: \.statistics))
                .tag(TopFeature.Tab.statistics)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("screen.title.statistics")
                }

            SettingsScreen(store: store.scope(state: \.settings, action: \.settings))
                .tag(TopFeature.Tab.settings)
                .tabItem {
                    Image(systemName: "gear")
                    Text("screen.title.settings")
                }
        }
        .onLoad { store.send(.screen(.onLoad)) }
        .enableInjection()
    }
}
