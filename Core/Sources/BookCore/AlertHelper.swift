public import Foundation

public import ComposableArchitecture

public enum AlertHelper {
    public static func alert<Action>(from response: HTTPURLResponse, action: Action) -> AlertState<Action> {
        switch response.statusCode {
        case 429:
            .init(
                title: { .init("alert.title.limit_error") },
                actions: { .init(action: action, label: { .init("button.title.close") }) },
                message: { .init("alert.message.limit_error") }
            )
        default:
            .init(
                title: { .init("alert.title.server_error: \(response.statusCode)") },
                actions: { .init(action: action, label: { .init("button.title.close") }) },
                message: { .init("alert.message.server_error") }
            )
        }
    }

    public static func alert<Action>(from error: any Error, action: Action) -> AlertState<Action> {
        switch error {
        case URLError.timedOut:
            .init(
                title: { .init("alert.title.timedout_error") },
                actions: { .init(action: action, label: { .init("button.title.close") }) },
                message: { .init("alert.message.timedout_error") }
            )
        case URLError.networkConnectionLost,
             URLError.notConnectedToInternet,
             URLError.cannotLoadFromNetwork:
            .init(
                title: { .init("alert.title.connection_error") },
                actions: { .init(action: action, label: { .init("button.title.close") }) },
                message: { .init("alert.message.connection_error") }
            )
        default:
            .init(
                title: { .init("alert.title.unknown_error") },
                actions: { .init(action: action, label: { .init("button.title.close") }) },
                message: { .init("alert.message.unknown_error") }
            )
        }
    }
}
