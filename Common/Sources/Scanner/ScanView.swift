public import SwiftUI

public struct ScanView: View {
    let onCaptured: (String) -> Void

    public var body: some View {
        CameraView(onCaptured: onCaptured)
    }

    public init(onCaptured: @escaping (String) -> Void) {
        self.onCaptured = onCaptured
    }
}
