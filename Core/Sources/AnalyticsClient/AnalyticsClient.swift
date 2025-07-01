public import Dependencies

import Foundation
import DependenciesMacros

@DependencyClient
public struct AnalyticsClient: Sendable {
    public var log: @Sendable (String, [String: Any]?) -> Void
}

public extension AnalyticsClient {
    enum Event {
        public enum Books {
            case registered(count: Int)
            case removed
        }

        case books(Books)
    }

    func log(event: Event) {
        let (name, parameters) = convert(from: event)
        log(name, parameters)
    }
}

func convert(from event: AnalyticsClient.Event) -> (String, [String: Any]?) {
    switch event {
    case let .books(.registered(count)):
        (
            "books",
            [
                "kind": "registered",
                "count": count,
            ]
        )
    case .books(.removed):
        (
            "books",
            [
                "kind": "removed",
            ]
        )
    }
}

extension AnalyticsClient: DependencyKey {
    public static let liveValue: AnalyticsClient = .init()
}
