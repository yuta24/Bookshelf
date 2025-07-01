public import StoreKit

public import ComposableArchitecture

import Foundation

@Reducer
public struct SupportFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var groupID: String
        public var products: [Product]?
        public var isProfileInstalled: Bool = false
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            case onInAppPurchaseCompletion(Result<Product.PurchaseResult, any Error>)
        }

        @CasePathable
        public enum DelegateAction: Sendable {
            case onInAppPurchased(Result<Product.PurchaseResult, any Error>)
        }

        case screen(ScreenAction)
        case delegate(DelegateAction)
    }

    public var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case let .screen(.onInAppPurchaseCompletion(result)):
                .send(.delegate(.onInAppPurchased(result)))
            case .delegate:
                .none
            }
        }
    }
}
