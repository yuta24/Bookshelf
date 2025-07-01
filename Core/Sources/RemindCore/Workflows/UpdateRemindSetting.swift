import Foundation
import PushClient
import Functional

// swiftlint:disable line_length

public typealias UpdateRemindSetting = (_ setting: RemindSetting) async throws -> RemindSetting

public func updateRemindSetting(_ setting: RemindSetting) -> Reader<(RemindSettingRepository, PushClient), RemindSetting> {
    .init { repository, _ in
        try await repository.update(setting)
        return setting
    }
}
