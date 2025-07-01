public import SyncClient

import Foundation
import SyncModel

extension SyncClient {
    enum Key {
        static let sync = "sync"
    }

    public static func generate(_ notify: @escaping @Sendable (Bool) -> Void) -> SyncClient {
        .init(
            fetch: {
                let enabled = UserDefaults.standard.value(forKey: Key.sync) as? Bool
                return enabled.flatMap(Sync.init)
            },
            update: { sync in
                UserDefaults.standard.set(sync.enabled, forKey: Key.sync)
                notify(sync.enabled)
            }
        )
    }
}
