import Testing
import Foundation
import RemindModel
@testable import RemindClient
@testable import RemindClientLive

@Suite("RemindClient live implementation")
struct RemindClientLiveTests {
    private func makeIsolatedUserDefaults() -> UserDefaults {
        let suiteName = "test.remind-client.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("fetch returns .disabled when nothing has been stored yet")
    func fetchReturnsDisabledWhenEmpty() {
        let client = RemindClient.generate(userDefaults: makeIsolatedUserDefaults())

        #expect(client.fetch() == .disabled)
    }

    @Test("update followed by fetch round-trips the stored value")
    func updateThenFetchRoundTrips() {
        let client = RemindClient.generate(userDefaults: makeIsolatedUserDefaults())
        let remind = Remind.make(.wednesday)

        client.update(remind)

        #expect(client.fetch() == remind)
    }

    @Test("fetch falls back to .disabled instead of crashing when stored data is corrupted")
    func fetchRecoversFromCorruptedData() {
        let userDefaults = makeIsolatedUserDefaults()
        // Simulate a schema change or bit-rot: the stored value is not valid encoded `Remind`.
        userDefaults.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: RemindClient.Key.remind)
        let client = RemindClient.generate(userDefaults: userDefaults)

        #expect(client.fetch() == .disabled)
    }
}
