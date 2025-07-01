import UIKit
import AVFoundation
import CoreMotion

final class OrientationManager {
    private let motionManager: CMMotionManager

    init() {
        self.motionManager = .init()

        motionManager.accelerometerUpdateInterval = 1 / 30
    }

    func start(handler: @escaping (UIInterfaceOrientation) -> Void) {
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }

            if let orientation = self?.handleAccelerometerUpdate(data: data) {
                handler(orientation)
            }
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
    }

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
}
