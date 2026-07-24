import Foundation

/// A `FileManager` subclass that lets tests simulate an unavailable App Group container,
/// e.g. to exercise the "App Group misconfigured" fallback path without needing real entitlements.
///
/// `urls(for:in:)` is redirected to a unique per-instance temporary directory so fallback
/// tests never read or write real Documents-directory state.
final class StubFileManager: FileManager, @unchecked Sendable {
    private let containerURLOverride: URL?
    let fallbackDirectoryURL: URL

    init(containerURL: URL?) {
        self.containerURLOverride = containerURL
        self.fallbackDirectoryURL = FileManager.default.temporaryDirectory.appending(path: "stub-fallback-\(UUID().uuidString)")
        super.init()
        try? FileManager.default.createDirectory(at: fallbackDirectoryURL, withIntermediateDirectories: true)
    }

    override func containerURL(forSecurityApplicationGroupIdentifier groupIdentifier: String) -> URL? {
        containerURLOverride
    }

    override func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        [fallbackDirectoryURL]
    }
}
