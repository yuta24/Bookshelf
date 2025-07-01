import SwiftUI
import ComposableArchitecture
import Inject
import HotComponent

struct RootScreen: View {
    let store: StoreOf<RootFeature>

    @Environment(\.scenePhase)
    var scenePhase

    @ObserveInjection
    var inject

    var body: some View {
        TopScreen(store: store.scope(state: \.top, action: \.top))
            .onChange(of: scenePhase) { _, newValue in
                store.send(.screen(.onChange(newValue)))
            }
            .onLoad {
                store.send(.screen(.onLoad))
            }
            .enableInjection()
    }
}
