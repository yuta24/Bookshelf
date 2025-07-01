public import StoreKit

public import ComposableArchitecture

public import RemindModel

import Foundation
import OSLog
import CasePaths
import Application
import Device
import FeatureFlags
import RemindClient
import SyncClient

private let logger: Logger = .init(subsystem: "com.bivre.bookshelf.core", category: "SettingsFeature")

@Reducer
public struct SettingsFeature: Sendable {
    @Reducer
    public struct Destination: Sendable {
        public enum State: Equatable, Sendable {
            case support(SupportFeature.State)
        }

        public enum Action: Sendable {
            case support(SupportFeature.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: \.support, action: \.support) {
                SupportFeature()
            }
        }
    }

    @ObservableState
    public struct State: Equatable, Sendable {
        public var isSyncEnabled: Bool
        public var remind: Remind = .disabled

        public var groupID: String
        public var version: String = ""
        public var build: String = ""
        public var isPurchased: Bool?
        public var isProfileInstalled: Bool = false
        public var enableNotification: Bool = false
        public var enablePurchase: Bool = false

        @Presents
        public var destination: Destination.State?

        public var isNetworkActived: Bool = false

        public static func make(isSyncEnabled: Bool, groupID: String) -> State {
            .init(isSyncEnabled: isSyncEnabled, groupID: groupID)
        }

        mutating func update(by status: Product.SubscriptionInfo.Status) {
            if case .verified = status.transaction {
                isPurchased = true
            } else {
                isPurchased = false
            }
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            case onLoad
            case task
            case syncEnabledChanged(Bool)
            case remindEnabledChanged(Bool)
            case dayOfWeekChanged(DayOfWeek)
            case onSubscriptionStatusTask([Product.SubscriptionInfo.Status])
            case onSupportTapped
            case onNetworkTapped
            case onNetworkDismissed(Bool)
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case load
            case loaded(TaskResult<(Bool, Remind, String, Int, Bool)>) // swiftlint:disable:this large_tuple
        }

        @CasePathable
        public enum ExternalAction: Sendable {
            case transaction(Product.SubscriptionInfo.Status)
        }

        case destination(PresentationAction<Destination.Action>)

        case screen(ScreenAction)
        case `internal`(InternalAction)
        case external(ExternalAction)
    }

    @Dependency(Application.self)
    var application
    @Dependency(Device.self)
    var device
    @Dependency(FeatureFlags.self)
    var featureFlags
    @Dependency(RemindClient.self)
    var remindClient
    @Dependency(SyncClient.self)
    var syncClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination(.presented(.support(.delegate(.onInAppPurchased(.success(.success(.verified))))))):
                state.destination = nil
                return .none
            case .destination(.dismiss):
                state.destination = nil
                return .none
            case .destination:
                return .none
            case .screen(.onLoad):
                state.enablePurchase = featureFlags.enablePurchase()
                return .none
            case .screen(.task):
                if state.enablePurchase {
                    return .send(.internal(.load))
                        .merge(with: .run { send in
                            for await result in Transaction.updates {
                                logger.debug("\(result.debugDescription)")

                                if case let .verified(transaction) = result, transaction.revocationDate == nil {
                                    if let status = await transaction.subscriptionStatus {
                                        await send(.external(.transaction(status)))
                                    }

                                    await transaction.finish()
                                }
                            }
                        })
                } else {
                    return .send(.internal(.load))
                }
            case let .screen(.syncEnabledChanged(enabled)):
                state.isSyncEnabled = enabled
                syncClient.update(.init(enabled: enabled))
                return .none
            case let .screen(.remindEnabledChanged(enabled)):
                let remind: Remind = if enabled {
                    Remind.make(.saturday)
                } else {
                    .disabled
                }
                state.remind = remind
                remindClient.update(state.remind)
                return .none
            case let .screen(.dayOfWeekChanged(dayOfWeek)):
                guard case var .enabled(setting) = state.remind else { return .none }
                setting.dayOfWeek = dayOfWeek
                state.remind = .enabled(setting)
                remindClient.update(state.remind)
                return .none
            case let .screen(.onSubscriptionStatusTask(statuses)):
                if let status = statuses.first {
                    state.update(by: status)
                } else {
                    state.isPurchased = false
                }
                return .none
            case .screen(.onSupportTapped):
                state.destination = .support(.init(groupID: state.groupID))
                return .none
            case .screen(.onNetworkTapped):
                state.isNetworkActived = true
                return .none
            case let .screen(.onNetworkDismissed(isActived)):
                state.isNetworkActived = isActived
                return .none
            case .internal(.load):
                return .run { send in
                    let sync = syncClient.fetch()
                    let remind = remindClient.fetch()
                    await send(.internal(.loaded(.success((
                        sync?.enabled ?? false,
                        remind,
                        application.version(),
                        application.build(),
                        device.isProfileInstalled()
                    )))))
                } catch: { error, send in
                    await send(.internal(.loaded(.failure(error))))
                }
            case let .internal(.loaded(.success((isSyncEnabled, remind, version, build, installed)))):
                state.isSyncEnabled = isSyncEnabled
                state.remind = remind
                state.version = version
                state.build = "\(build)"
                state.isProfileInstalled = installed
                return .none
            case .internal(.loaded(.failure)):
                return .none
            case let .external(.transaction(status)):
                state.update(by: status)
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) { Destination() }
    }
}
