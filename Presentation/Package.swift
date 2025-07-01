// swift-tools-version: 6.0

@preconcurrency import PackageDescription

let buildTimeOptimizationSwiftFlags: [String] = [
    "-Xfrontend", "-warn-long-function-bodies=100",
    "-Xfrontend", "-warn-long-expression-type-checking=100",
]

let defaultSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .unsafeFlags(buildTimeOptimizationSwiftFlags, .when(configuration: .debug)),
]

extension Target.Dependency {
    static let Inject: Target.Dependency = .product(name: "Inject", package: "Inject")
    static let NukeUI: Target.Dependency = .product(name: "NukeUI", package: "Nuke")
    static let PulseUI: Target.Dependency = .product(name: "PulseUI", package: "Pulse")
    static let SnapshotTesting: Target.Dependency = .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
}

extension String {
    static let AccessibilityHelper = "AccessibilityHelper"
    static let Presentation = "Presentation"
    static let PresentationTests = "PresentationTests"
}

let otherTargets: [Target] = [
]

let presentationTargets: [Target] = [
    .target(
        name: .AccessibilityHelper,
        dependencies: []
    ),
    .target(
        name: .Presentation,
        dependencies: [
            .product(name: "Scanner", package: "Common"),
            .product(name: "AnalyticsClient", package: "Core"),
            .product(name: "BookCore", package: "Core"),
            .product(name: "Device", package: "Core"),
            .product(name: "FeatureFlags", package: "Core"),
            .product(name: "GenreClient", package: "Core"),
            .product(name: "SettingsCore", package: "Core"),
            .product(name: "StatisticsCore", package: "Core"),
            .product(name: "WidgetUpdater", package: "Core"),
            .product(name: "PreReleaseNotificationModel", package: "Core"),
            .product(name: "HotComponent", package: "Experiment"),
            .product(name: "RemoteUI", package: "Experiment"),
            .Inject,
            .NukeUI,
            .PulseUI,
        ],
        resources: [
            .process("Resource/Hot.json"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .testTarget(
        name: .PresentationTests,
        dependencies: [
            .target(name: .Presentation),
            .SnapshotTesting,
        ]
    ),
]

let package = Package(
    name: "Presentation",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: .Presentation,
            targets: [
                .AccessibilityHelper,
                .Presentation,
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kean/Nuke.git", exact: "12.8.0"),
        .package(url: "https://github.com/kean/Pulse.git", exact: "5.1.4"),
        .package(url: "https://github.com/krzysztofzablocki/Inject.git", exact: "1.5.2"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", exact: "1.18.4"),
        .package(path: "../Common"),
        .package(path: "../Core"),
        .package(path: "../Experiment"),
    ],
    targets: otherTargets + presentationTargets
)
