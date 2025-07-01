@preconcurrency public import FirebaseRemoteConfig

public import GenreClient

import Foundation
import GenreModel

extension GenreClient {
    enum Key {
        enum Genre {
            static let current = "genre.current"
        }
    }

    public static func generate(_ remoteConfig: RemoteConfig) -> GenreClient {
        remoteConfig.setDefaults(fromPlist: "RemoteConfigDefaults")

        return .init(
            fetch: {
                _ = try await remoteConfig.fetchAndActivate()
                let value = remoteConfig.configValue(forKey: "genres")
                return try JSONDecoder().decode([Genre].self, from: value.dataValue)
            })
    }
}
