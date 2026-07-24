import Testing
import Foundation
@testable import Infrastructure

/// Tests that the shared-store URL resolution and database creation degrade gracefully
/// (instead of crashing) when the App Group container is unavailable, e.g. due to a
/// provisioning/entitlement misconfiguration.
@Suite("Persistent store fallback")
struct PersistentStoreFallbackTests {
    @Test("makeSharedStoreURL uses the App Group container when available")
    func usesAppGroupContainerWhenAvailable() {
        let appGroupURL = FileManager.default.temporaryDirectory.appending(path: "app-group-\(UUID().uuidString)")
        let manager = StubFileManager(containerURL: appGroupURL)

        let url = makeSharedStoreURL("group.test", with: manager)

        #expect(url == appGroupURL.appending(path: "Client.sqlite"))
    }

    @Test("makeSharedStoreURL falls back to the documents directory when the App Group container is unavailable")
    func fallsBackWhenAppGroupContainerUnavailable() {
        let manager = StubFileManager(containerURL: nil)

        let url = makeSharedStoreURL("group.unavailable", with: manager)

        let documentsURL = manager.urls(for: .documentDirectory, in: .userDomainMask).first ?? manager.temporaryDirectory
        #expect(url == documentsURL.appending(path: "Client.sqlite"))
    }

    @Test("createDatabase does not crash and still produces a usable database when the App Group container is unavailable")
    func createDatabaseFallsBackWhenAppGroupContainerUnavailable() throws {
        let manager = StubFileManager(containerURL: nil)

        let database = try createDatabase(id: "group.unavailable", with: manager)

        let count = try database.read { db in
            try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM tags") ?? -1
        }
        #expect(count == 0)
    }
}
