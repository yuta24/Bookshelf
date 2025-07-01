import SwiftUI
import StoreKit
import ComposableArchitecture
import Inject
import PulseUI
import SettingsCore

struct SupportScreen: View {
    let store: StoreOf<SupportFeature>

    @ObserveInjection
    var inject

    var body: some View {
        NavigationStack {
            SubscriptionStoreView(groupID: store.groupID)
                .navigationTitle("screen.title.support")
                .navigationBarTitleDisplayMode(.inline)
                .onInAppPurchaseCompletion { _, result in
                    store.send(.screen(.onInAppPurchaseCompletion(result)))
                }
        }
        .enableInjection()
    }
}
