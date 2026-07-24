public import RemindClient

import Foundation
import OSLog
import RemindModel

private let logger = Logger(subsystem: "com.bivre.bookshelf", category: "RemindClient")

/// `UserDefaults` is thread-safe but not marked `Sendable` by Foundation, so it can't be
/// captured directly in the `@Sendable` closures below. This box vouches for it locally
/// without retroactively conforming `UserDefaults` to `Sendable` module-wide.
private struct UncheckedSendableBox<Value>: @unchecked Sendable {
    let value: Value
}

extension RemindClient {
    enum Key {
        static let remind = "remind"
    }

    public static func generate(userDefaults: UserDefaults = .standard) -> RemindClient {
        let encoder: JSONEncoder = .init()
        let decoder: JSONDecoder = .init()
        let userDefaultsBox = UncheckedSendableBox(value: userDefaults)

        return .init(
            fetch: {
                let userDefaults = userDefaultsBox.value

                guard let encoded = userDefaults.value(forKey: Key.remind) as? Data else {
                    return .disabled
                }

                do {
                    return try decoder.decode(Remind.self, from: encoded)
                } catch {
                    logger.error("Failed to decode Remind, resetting to disabled: \(error.localizedDescription)")
                    return .disabled
                }
            },
            update: { remind in
                do {
                    let encoded = try encoder.encode(remind)
                    userDefaultsBox.value.set(encoded, forKey: Key.remind)
                } catch {
                    logger.error("Failed to encode Remind: \(error.localizedDescription)")
                }
            }
        )
    }
}
