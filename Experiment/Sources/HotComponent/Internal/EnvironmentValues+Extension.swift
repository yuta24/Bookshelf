import SwiftUI

private struct ComponentContainerKey: EnvironmentKey {
    static var defaultValue: ComponentContainer = .default
}

extension EnvironmentValues {
    var container: ComponentContainer {
        get { self[ComponentContainerKey.self] }
        set { self[ComponentContainerKey.self] = newValue }
    }
}
