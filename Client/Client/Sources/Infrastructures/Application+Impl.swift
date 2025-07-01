import Foundation
import UIKit
import Application

extension Application {
    static func generate() -> Application {
        .init(
            identifier: {
                // swiftlint:disable:next force_cast
                Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
            },
            build: {
                // swiftlint:disable:next force_cast
                let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
                return Int(build)!
            },
            version: {
                // swiftlint:disable:next force_cast
                Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            },
            open: { @MainActor in
                UIApplication.shared.open($0, options: $1, completionHandler: $2)
            }
        )
    }
}
