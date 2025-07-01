public import AnalyticsClient

import Foundation
import FirebaseAnalytics

public extension AnalyticsClient {
    static func generate() -> AnalyticsClient {
        .init(
            log: { name, parameters in
                Analytics.logEvent(name, parameters: parameters)
            })
    }
}
