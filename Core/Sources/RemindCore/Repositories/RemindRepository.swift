import Foundation

public protocol RemindRepository {
    func fetch() async throws -> Remind?
    @discardableResult
    func update(_ remind: Remind) async throws -> Remind
    func delete() async throws
}
