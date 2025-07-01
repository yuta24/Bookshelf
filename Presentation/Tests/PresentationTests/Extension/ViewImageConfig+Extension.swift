import UIKit
import SnapshotTesting

extension ViewImageConfig {
    public static let iPhone15 = ViewImageConfig.iPhone15(.portrait)

    static func iPhone15(_ orientation: Orientation) -> ViewImageConfig {
        let safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .zero
            size = .init(width: 852, height: 393)
        case .portrait:
            safeArea = .init(top: 59, left: 59, bottom: 34, right: 59)
            size = .init(width: 393, height: 852)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone8(orientation))
    }

    public static let iPhone16 = ViewImageConfig.iPhone16(.portrait)

    static func iPhone16(_ orientation: Orientation) -> ViewImageConfig {
        let safeArea: UIEdgeInsets
        let size: CGSize
        switch orientation {
        case .landscape:
            safeArea = .zero
            size = .init(width: 852, height: 393)
        case .portrait:
            safeArea = .init(top: 59, left: 59, bottom: 34, right: 59)
            size = .init(width: 393, height: 852)
        }
        return .init(safeArea: safeArea, size: size, traits: .iPhone8(orientation))
    }
}
