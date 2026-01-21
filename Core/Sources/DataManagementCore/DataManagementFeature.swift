public import ComposableArchitecture
public import Dependencies
import Foundation
import OSLog
import CasePaths
import BookModel
import DataClient

private let logger: Logger = .init(subsystem: "com.bivre.bookshelf.core", category: "DataManagementFeature")

@Reducer
public struct DataManagementFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var json: String?

        @Presents
        public var alert: AlertState<Action.AlertAction>?

        public init() {}
    }

    @CasePathable
    public enum Action: Sendable {
        @CasePathable
        public enum ScreenAction: Sendable {
            case onLoad
            case imported(URL)
        }

        @CasePathable
        public enum InternalAction: Sendable {
            case loaded(Result<String?, any Error>)
            case imported(Result<Void, any Error>)
        }

        @CasePathable
        public enum AlertAction: Sendable {
            case dismiss
        }

        case screen(ScreenAction)
        case `internal`(InternalAction)
        case alert(PresentationAction<AlertAction>)
    }

    @Dependency(DataClient.self)
    var dataClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .screen(.onLoad):
                return .run { send in
                    let json = try await dataClient.export()
                    await send(.internal(.loaded(.success(json))))
                } catch: { error, send in
                    await send(.internal(.loaded(.failure(error))))
                }

            case .screen(.imported(let url)):
                return .run { send in
                    let accessing = url.startAccessingSecurityScopedResource()
                    defer {
                        if accessing {
                            url.stopAccessingSecurityScopedResource()
                        }
                    }

                    let data = try Data(contentsOf: url)
                    try await dataClient.import(data)
                    await send(.internal(.imported(.success(()))))
                } catch: { error, send in
                    await send(.internal(.imported(.failure(error))))
                }

            case .internal(.loaded(.success(let json))):
                state.json = json
                return .none

            case .internal(.loaded(.failure)):
                // TODO: エラーハンドリング（アラート表示など）
                return .none

            case .internal(.imported(.success)):
                return .none

            case .internal(.imported(.failure)):
                // TODO: エラーハンドリング（アラート表示など）
                return .none

            case .alert(.presented(.dismiss)):
                state.alert = nil
                return .none

            case .alert(.dismiss):
                state.alert = nil
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
