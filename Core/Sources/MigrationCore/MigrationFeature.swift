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
            case migrationProgress(Int, Int)
            case migrationCompleted
            case migrationFailed(String)
        }

        @CasePathable
        public enum ExternalAction: Sendable {
            case migrationFinished
            case migrationSkipped
        }

        @CasePathable
        public enum Alert: Sendable {
            case dismiss
        }

        case screen(ScreenAction)
        case `internal`(InternalAction)
        case external(ExternalAction)
        case alert(PresentationAction<Alert>)
    }

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
                return .send(.external(.migrationSkipped))

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
                        try await migrationClient.performMigration { current, total in
                            await send(.internal(.migrationProgress(current, total)))
                        }
                        try await migrationClient.markCompleted()
                        await send(.internal(.migrationCompleted))
                    } catch {
                        await send(.internal(.migrationFailed(error.localizedDescription)))
                    }
                }

            case let .internal(.migrationProgress(current, total)):
                state.migratedCount = current
                let progress = total > 0 ? Double(current) / Double(total) : 0
                state.migrationState = .migrating(progress: progress)
                return .none

            case .internal(.migrationCompleted):
                state.migrationState = .completed
                state.completionAlert = AlertState {
                    TextState("マイグレーション完了")
                } actions: {
                    ButtonState(action: .dismiss) {
                        TextState("OK")
                    }
                } message: {
                    TextState("データベースの移行が完了しました。\n変更を反映するには、アプリを手動で再起動してください。")
                }
                logger.info("Migration completed successfully")
                return .none

            case let .internal(.migrationFailed(error)):
                state.migrationState = .failed(error: error)
                logger.error("Migration failed: \(error)")
                return .none

            case .alert(.presented(.dismiss)):
                return .send(.external(.migrationFinished))

            case .alert(.dismiss):
                return .send(.external(.migrationFinished))

            case .external:
                return .none
            }
        }
        .ifLet(\.$completionAlert, action: \.alert)
    }
}
