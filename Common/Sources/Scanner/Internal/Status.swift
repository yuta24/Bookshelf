import Foundation
import AVFoundation

enum Status {
    case available
    case unavailable

    init?(_ status: AVAuthorizationStatus) {
        switch status {
        case .notDetermined:
            return nil
        case .restricted:
            self = .unavailable
        case .denied:
            self = .unavailable
        case .authorized:
            self = .available
        @unknown default:
            return nil
        }
    }
}
