// swift-tools-version: 6.2.1

import PackageDescription

let buildTimeOptimizationSwiftFlags: [String] = [
    "-Xfrontend", "-warn-long-function-bodies=100",
    "-Xfrontend", "-warn-long-expression-type-checking=100",
]

let defaultSwiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .unsafeFlags(buildTimeOptimizationSwiftFlags, .when(configuration: .debug)),
]

let targets: [Target] = [
    .target(
        name: "AnalyticsClientLive",
        dependencies: [
            .product(name: "AnalyticsClient", package: "Core"),
            .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "BookClientLive",
        dependencies: [
            .target(name: "BookRecord"),
            .target(name: "Infrastructure"),
            .product(name: "BookClient", package: "Core"),
            .product(name: "BookModel", package: "Core"),
            .product(name: "GenreModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "BookRecord",
        dependencies: [
            .product(name: "BookModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "GenreClientLive",
        dependencies: [
            .product(name: "GenreClient", package: "Core"),
            .product(name: "GenreModel", package: "Core"),
            .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "Infrastructure",
        dependencies: [
            .target(name: "BookRecord"),
            .product(name: "SQLiteData", package: "sqlite-data"),
            .product(name: "MigrationCore", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .testTarget(
        name: "InfrastructureTests",
        dependencies: [
            .target(name: "Infrastructure"),
            .target(name: "BookRecord"),
            .product(name: "BookModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "PushClientLive",
        dependencies: [
            .product(name: "PushClient", package: "Core"),
            .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "RemindClientLive",
        dependencies: [
            .product(name: "RemindModel", package: "Core"),
            .product(name: "RemindClient", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "SearchClientLive",
        dependencies: [
            .product(name: "SearchClient", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "ShelfClientLive",
        dependencies: [
            .target(name: "BookRecord"),
            .target(name: "Infrastructure"),
            .product(name: "ShelfClient", package: "Core"),
            .product(name: "BookModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "SyncClientLive",
        dependencies: [
            .product(name: "SyncClient", package: "Core"),
            .product(name: "SyncModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "TagClientLive",
        dependencies: [
            .target(name: "BookRecord"),
            .target(name: "Infrastructure"),
            .product(name: "TagClient", package: "Core"),
            .product(name: "BookModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: "PreReleaseNotificationClientLive",
        dependencies: [
            .product(name: "PreReleaseNotificationClient", package: "Core"),
            .product(name: "PreReleaseNotificationModel", package: "Core"),
            .product(name: "BookModel", package: "Core"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
]

let package = Package(
    name: "Infrastructure",
    platforms: [.iOS(.v17)],
    products: [
        .library(
            name: "AnalyticsClientLive",
            targets: ["AnalyticsClientLive"]
        ),
        .library(
            name: "BookClientLive",
            targets: ["BookClientLive"]
        ),
        .library(
            name: "GenreClientLive",
            targets: ["GenreClientLive"]
        ),
        .library(
            name: "Infrastructure",
            targets: ["Infrastructure"]
        ),
        .library(
            name: "PushClientLive",
            targets: ["PushClientLive"]
        ),
        .library(
            name: "RemindClientLive",
            targets: ["RemindClientLive"]
        ),
        .library(
            name: "SearchClientLive",
            targets: ["SearchClientLive"]
        ),
        .library(
            name: "ShelfClientLive",
            targets: ["ShelfClientLive"]
        ),
        .library(
            name: "SyncClientLive",
            targets: ["SyncClientLive"]
        ),
        .library(
            name: "TagClientLive",
            targets: ["TagClientLive"]
        ),
        .library(
            name: "PreReleaseNotificationClientLive",
            targets: ["PreReleaseNotificationClientLive"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", exact: "12.8.0"),
        .package(url: "https://github.com/pointfreeco/sqlite-data.git", exact: "1.5.0"),
        .package(path: "../Core"),
    ],
    targets: targets
)
