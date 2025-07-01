import Foundation
import PushClient
import Functional

public typealias DisableRemind = () async throws -> RemindSetting

public func disableRemind() -> Reader<(RemindSettingRepository, PushClient), RemindSetting> {
    .init { repository, push in
        let settings = await push.getNotificationSettings()
        var setting = try await repository.fetch() ??
            .init(enabled: false, authorizationStatus: settings.authorizationStatus, dayOfWeek: .saturday, hour: 8)
        setting.enabled = false
        setting.dayOfWeek = .saturday
        setting.hour = 8
        setting.authorizationStatus = settings.authorizationStatus
        try await repository.update(setting)
        return setting
    }
}
