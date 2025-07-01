public import RemindClient

import Foundation
import RemindModel

extension RemindClient {
    enum Key {
        static let remind = "remind"
    }

    public static func generate() -> RemindClient {
        let encoder: JSONEncoder = .init()
        let decoder: JSONDecoder = .init()

        return .init(
            fetch: {
                let encoded = UserDefaults.standard.value(forKey: Key.remind) as? Data
                return encoded.flatMap { try! decoder.decode(Remind.self, from: $0) } ?? .disabled
            },
            update: { remind in
                let encoded = try! encoder.encode(remind)
                UserDefaults.standard.set(encoded, forKey: Key.remind)
            }
        )
    }
}
