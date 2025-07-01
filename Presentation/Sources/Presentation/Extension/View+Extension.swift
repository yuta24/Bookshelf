public import SwiftUI

extension View {
    @inlinable func frame(size: CGSize? = nil, alignment: Alignment = .center) -> some View {
        frame(width: size?.width, height: size?.height, alignment: alignment)
    }
}
