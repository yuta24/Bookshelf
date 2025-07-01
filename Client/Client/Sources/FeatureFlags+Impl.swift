import Foundation
import Device
import FeatureFlags

extension FeatureFlags {
    static func generate(_ device: Device) -> FeatureFlags {
        .init(
            enableNotification: {
                device.isProfileInstalled()
            },
            enableBooks: {
                device.isProfileInstalled()
            },
            enablePurchase: {
                device.isProfileInstalled()
            },
            enableImport: {
                device.isProfileInstalled()
            },
            enableExport: {
                device.isProfileInstalled()
            }
        )
    }
}
