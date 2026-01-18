public import ComposableArchitecture
public import Dependencies
import Foundation
import OSLog

private let logger: Logger = .init(subsystem: "com.bivre.bookshelf.core", category: "MigrationFeature")

@Reducer
public struct MigrationFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public enum MigrationState: Equatable, Sendable {
            case idle
            case checking
            case migrating(progress: Double)
            case completed
            case failed(error: String)
        }

        public var migrationState: MigrationState = .idle
        public var bookCount: Int = 0
        public var migratedCount: Int = 0

        @Presents
        public var completionAlert: AlertState<Action.Alert>?

        public init(migrationState: MigrationState = .idle) {
            self.migrationState = migrationState
        }
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            case onAppear
            case startMigration
            case skipMigration
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case checkMigrationNeeded
            case migrationCheckCompleted(Bool, Int)
            case performMigration
            case migrationCompleted
            case migrationFailed(String)
        }

        @CasePathable
        public enum ExternalAction: Sendable {
            case migrationFinished
            case migrationSkipped
        }

        @CasePathable
        public enum DelegateAction: Sendable {
            case migrationCompleted
        }

        @CasePathable
        public enum Alert: Sendable {
            case dismiss
        }

        case screen(ScreenAction)
        case `internal`(InternalAction)
        case external(ExternalAction)
        case delegate(DelegateAction)
        case alert(PresentationAction<Alert>)
    }

    @Dependency(\.dismiss)
    var dismiss
    @Dependency(\.migrationClient)
    var migrationClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .screen(.onAppear):
                return .send(.internal(.checkMigrationNeeded))

            case .screen(.startMigration):
                state.migrationState = .migrating(progress: 0)
                return .send(.internal(.performMigration))

            case .screen(.skipMigration):
                return .run { _ in
                    await dismiss()
                }

            case .internal(.checkMigrationNeeded):
                state.migrationState = .checking
                return .run { send in
                    do {
                        let isNeeded = try await migrationClient.requiresMigration()
                        let count = isNeeded ? try await migrationClient.getBookCount() : 0
                        await send(.internal(.migrationCheckCompleted(isNeeded, count)))
                    } catch {
                        await send(.internal(.migrationFailed(error.localizedDescription)))
                    }
                }

            case let .internal(.migrationCheckCompleted(isNeeded, count)):
                if isNeeded {
                    state.migrationState = .idle
                    state.bookCount = count
                } else {
                    state.migrationState = .completed
                    return .send(.external(.migrationFinished))
                }
                return .none

            case .internal(.performMigration):
                return .run { send in
                    do {
                        try await migrationClient.performMigration()
                        try await migrationClient.markCompleted()
                        await send(.internal(.migrationCompleted))
                    } catch {
                        await send(.internal(.migrationFailed(error.localizedDescription)))
                    }
                }

            case .internal(.migrationCompleted):
                state.migrationState = .completed
                state.completionAlert = AlertState {
                    TextState(String(localized: "alert.title.migration_completed"))
                } actions: {
                    ButtonState(action: .dismiss) {
                        TextState(String(localized: "button.title.close"))
                    }
                } message: {
                    TextState(String(localized: "alert.message.migration_completed"))
                }
                logger.info("Migration completed successfully")
                return .none

            case let .internal(.migrationFailed(error)):
                state.migrationState = .failed(error: error)
                logger.error("Migration failed: \(error)")
                return .none

            case .alert(.presented(.dismiss)):
                return .send(.delegate(.migrationCompleted))
                    .merge(with: .send(.external(.migrationFinished)))

            case .alert(.dismiss):
                return .send(.delegate(.migrationCompleted))
                    .merge(with: .send(.external(.migrationFinished)))

            case .delegate:
                return .none

            case .external:
                return .none
            }
        }
        .ifLet(\.$completionAlert, action: \.alert)
    }
}
