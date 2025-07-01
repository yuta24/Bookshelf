import Foundation

public protocol RemindSettingRepository {
    func fetch() async throws -> RemindSetting?
    @discardableResult
    func update(_ setting: RemindSetting) async throws -> RemindSetting
    func delete() async throws
}
