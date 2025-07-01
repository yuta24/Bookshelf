import SwiftUI

extension EnvironmentValues {
    private struct RemoteContainerKey: EnvironmentKey {
        static let defaultValue: RemoteContainer = .default
    }

    var remoteContainer: RemoteContainer {
        get { self[RemoteContainerKey.self] }
        set { self[RemoteContainerKey.self] = newValue }
    }
}
