import Foundation
import Presentation
import Device

extension Device {
    static func generate() -> Device {
        let fileURLString = Bundle.main.path(forResource: "SwiftDeviceAuthority-Leaf", ofType: "cer")

        return .init(
            isProfileInstalled: {
                guard let data = fileURLString.flatMap({ NSData(contentsOfFile: $0) }) else { return false }
                guard let certificate = SecCertificateCreateWithData(nil, data as CFData) else { return false }

                let policy = SecPolicyCreateBasicX509()

                var trust: SecTrust?
                _ = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)

                guard let trust else { return false }

                var error: CFError?
                return SecTrustEvaluateWithError(trust, &error)
            }
        )
    }
}
