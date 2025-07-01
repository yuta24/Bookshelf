import SnapshotTesting
import UIKit

extension SwiftUISnapshotLayout {
    @MainActor
    static var screen: Self {
        .fixed(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
}
