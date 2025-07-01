import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    let onCaptured: (String) -> Void

    func makeUIViewController(context _: Context) -> CameraViewController {
        .init(onCaptured: onCaptured)
    }

    func updateUIViewController(_: CameraViewController, context _: Context) {}
}
