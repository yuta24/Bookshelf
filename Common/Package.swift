// swift-tools-version: 5.10

import PackageDescription

let buildTimeOptimizationSwiftFlags: [String] = [
    "-Xfrontend", "-warn-long-function-bodies=100",
    "-Xfrontend", "-warn-long-expression-type-checking=100",
]

let defaultSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("ExistentialAny"),
//    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("GlobalConcurrency"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("IsolatedDefaultValues"),
    .enableUpcomingFeature("StrictConcurrency"),
    .unsafeFlags(buildTimeOptimizationSwiftFlags, .when(configuration: .debug)),
]

extension String {
    static let Scanner = "Scanner"
    static let Updater = "Updater"
}

let package = Package(
    name: "Common",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: .Scanner, targets: [.Scanner]),
        .library(name: .Updater, targets: [.Updater]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: .Scanner,
            dependencies: [],
            swiftSettings: defaultSwiftSettings
        ),
        .target(
            name: .Updater,
            dependencies: [],
            swiftSettings: defaultSwiftSettings
        ),
    ]
)
