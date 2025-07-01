import Foundation
import PushClient
import Functional

public typealias EnableRemind = () async throws -> RemindSetting

public func enableRemind() -> Reader<(RemindSettingRepository, PushClient), RemindSetting> {
    .init { repository, push in
        let granted = try await push.requestAuthorization([.alert, .sound, .badge])
        let settings = await push.getNotificationSettings()
        var setting = try await repository.fetch() ??
            .init(enabled: false, authorizationStatus: settings.authorizationStatus, dayOfWeek: .saturday, hour: 8)
        setting.enabled = granted
        setting.authorizationStatus = settings.authorizationStatus
        try await repository.update(setting)
        return setting
    }
}
