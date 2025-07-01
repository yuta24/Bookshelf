import Foundation
import PushClient
import Functional

public typealias GetRemindSetting = () async throws -> RemindSetting

public func getRemindSetting() -> Reader<(RemindSettingRepository, PushClient), RemindSetting> {
    .init { repository, push in
        let settings = await push.getNotificationSettings()
        var setting = try await repository.fetch() ??
            .init(enabled: false, authorizationStatus: settings.authorizationStatus, dayOfWeek: .saturday, hour: 8)
        setting.authorizationStatus = settings.authorizationStatus
        try await repository.update(setting)
        return setting
    }
}
