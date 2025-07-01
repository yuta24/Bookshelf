import UIKit
import AVFoundation
import CoreMotion

private func handleAccelerometerUpdate(data: CMAccelerometerData) -> UIInterfaceOrientation {
    if abs(data.acceleration.y) < abs(data.acceleration.x) {
        if data.acceleration.x > 0 {
            .landscapeLeft
        } else {
            .landscapeRight
        }
    } else {
        if data.acceleration.y > 0 {
            .portraitUpsideDown
        } else {
            .portrait
        }
    }
}

final class Orientation {
    private(set) var interfaceOrientation: UIInterfaceOrientation = .unknown

    private let motionManager: CMMotionManager = .init()

    init() {
        motionManager.accelerometerUpdateInterval = 0.1
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }

            self?.interfaceOrientation = handleAccelerometerUpdate(data: data)
        }
    }

    deinit {
        motionManager.stopAccelerometerUpdates()
    }
}
