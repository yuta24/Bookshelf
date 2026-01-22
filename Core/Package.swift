// swift-tools-version: 6.2.1

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
    static let ComposableArchitecture: Target.Dependency = .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
    static let SwiftNavigation: Target.Dependency = .product(name: "SwiftNavigation", package: "swift-navigation")
    static let OrderedCollections: Target.Dependency = .product(name: "OrderedCollections", package: "swift-collections")
    static let Updater: Target.Dependency = .product(name: "Updater", package: "Common")
}

extension String {
    // Common
    static let Application = "Application"
    static let Device = "Device"
    static let FeatureFlags = "FeatureFlags"
    static let WidgetUpdater = "WidgetUpdater"

    // Domain
    static let BookModel = "BookModel"
    static let GenreModel = "GenreModel"
    static let RemindModel = "RemindModel"
    static let SyncModel = "SyncModel"
    static let PreReleaseNotificationModel = "PreReleaseNotificationModel"

    // Client
    static let AnalyticsClient = "AnalyticsClient"
    static let BookClient = "BookClient"
    static let DataClient = "DataClient"
    static let GenreClient = "GenreClient"
    static let PushClient = "PushClient"
    static let RemindClient = "RemindClient"
    static let SearchClient = "SearchClient"
    static let ShelfClient = "ShelfClient"
    static let SyncClient = "SyncClient"
    static let TagClient = "TagClient"
    static let PreReleaseNotificationClient = "PreReleaseNotificationClient"

    // Core
    static let BookCore = "BookCore"
    static let DataManagementCore = "DataManagementCore"
    static let MigrationCore = "MigrationCore"
    static let SettingsCore = "SettingsCore"
    static let StatisticsCore = "StatisticsCore"

    // Tests
    static let BookCoreTests = "BookCoreTests"
}

let commonTargets: [Target] = [
    .target(
        name: .Application,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .Device,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .FeatureFlags,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .WidgetUpdater,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
]

let domainTargets: [Target] = [
    .target(
        name: .BookModel,
        dependencies: [
            .product(name: "Tagged", package: "swift-tagged"),
            .product(name: "SQLiteData", package: "sqlite-data"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .GenreModel,
        dependencies: [
            .product(name: "Tagged", package: "swift-tagged"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .RemindModel,
        dependencies: [
            .product(name: "Tagged", package: "swift-tagged"),
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .SyncModel,
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .PreReleaseNotificationModel,
        dependencies: [
            .target(name: .BookModel),
        ],
        swiftSettings: defaultSwiftSettings
    ),
]

let clientTargets: [Target] = [
    .target(
        name: .AnalyticsClient,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .BookClient,
        dependencies: [
            .target(name: .BookModel),
            .target(name: .GenreModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .DataClient,
        dependencies: [
            .target(name: .BookModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .GenreClient,
        dependencies: [
            .target(name: .GenreModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .PushClient,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .RemindClient,
        dependencies: [
            .target(name: .RemindModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .SearchClient,
        dependencies: [
            .target(name: .BookModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .ShelfClient,
        dependencies: [
            .target(name: .BookModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .SyncClient,
        dependencies: [
            .target(name: .SyncModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .TagClient,
        dependencies: [
            .target(name: .BookModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .PreReleaseNotificationClient,
        dependencies: [
            .target(name: .PreReleaseNotificationModel),
            .target(name: .BookModel),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
]

let coreTargets: [Target] = [
    .target(
        name: .BookCore,
        dependencies: [
            .target(name: .FeatureFlags),
            .target(name: .WidgetUpdater),
            .target(name: .AnalyticsClient),
            .target(name: .BookClient),
            .target(name: .BookModel),
            .target(name: .GenreModel),
            .target(name: .GenreClient),
            .target(name: .TagClient),
            .target(name: .SearchClient),
            .target(name: .ShelfClient),
            .target(name: .PreReleaseNotificationModel),
            .target(name: .PreReleaseNotificationClient),
            .ComposableArchitecture,
            .SwiftNavigation,
            .OrderedCollections,
            .Updater,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .DataManagementCore,
        dependencies: [
            .target(name: .BookModel),
            .target(name: .DataClient),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .MigrationCore,
        dependencies: [
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .SettingsCore,
        dependencies: [
            .target(name: .Application),
            .target(name: .DataManagementCore),
            .target(name: .Device),
            .target(name: .FeatureFlags),
            .target(name: .BookModel),
            .target(name: .DataClient),
            .target(name: .RemindClient),
            .target(name: .ShelfClient),
            .target(name: .SyncClient),
            .target(name: .MigrationCore),
            .ComposableArchitecture,
        ],
        swiftSettings: defaultSwiftSettings
    ),
    .target(
        name: .StatisticsCore,
        dependencies: [
            .target(name: .BookModel),
            .target(name: .ShelfClient),
            .ComposableArchitecture,
            .OrderedCollections,
        ],
        swiftSettings: defaultSwiftSettings
    ),
]

let testTargets: [Target] = [
    .testTarget(
        name: .BookCoreTests,
        dependencies: [
            .target(name: .BookCore),
        ]
    ),
]

let package = Package(
    name: "Core",
    platforms: [.iOS(.v17)],
    products: [
        // Common
        .library(name: .Application, targets: [.Application]),
        .library(name: .Device, targets: [.Device]),
        .library(name: .FeatureFlags, targets: [.FeatureFlags]),
        .library(name: .WidgetUpdater, targets: [.WidgetUpdater]),

        // Domain
        .library(name: .BookModel, targets: [.BookModel]),
        .library(name: .GenreModel, targets: [.GenreModel]),
        .library(name: .RemindModel, targets: [.RemindModel]),
        .library(name: .SyncModel, targets: [.SyncModel]),
        .library(name: .PreReleaseNotificationModel, targets: [.PreReleaseNotificationModel]),

        // Client
        .library(name: .AnalyticsClient, targets: [.AnalyticsClient]),
        .library(name: .BookClient, targets: [.BookClient]),
        .library(name: .DataClient, targets: [.DataClient]),
        .library(name: .GenreClient, targets: [.GenreClient]),
        .library(name: .PushClient, targets: [.PushClient]),
        .library(name: .RemindClient, targets: [.RemindClient]),
        .library(name: .SearchClient, targets: [.SearchClient]),
        .library(name: .ShelfClient, targets: [.ShelfClient]),
        .library(name: .SyncClient, targets: [.SyncClient]),
        .library(name: .TagClient, targets: [.TagClient]),
        .library(name: .PreReleaseNotificationClient, targets: [.PreReleaseNotificationClient]),

        // Core
        .library(name: .BookCore, targets: [.BookCore]),
        .library(name: .DataManagementCore, targets: [.DataManagementCore]),
        .library(name: .MigrationCore, targets: [.MigrationCore]),
        .library(name: .SettingsCore, targets: [.SettingsCore]),
        .library(name: .StatisticsCore, targets: [.StatisticsCore]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-collections.git", exact: "1.3.0"),
        .package(url: "https://github.com/pointfreeco/sqlite-data.git", exact: "1.5.0", traits: [.trait(name: "SQLiteDataTagged")]),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", exact: "1.22.3"),
        .package(url: "https://github.com/pointfreeco/swift-navigation.git", exact: "2.4.2"),
        .package(url: "https://github.com/pointfreeco/swift-tagged.git", exact: "0.10.0"),
        .package(path: "../Common"),
//        .package(path: "../Experiment"),
    ],
    targets: commonTargets + domainTargets + clientTargets + coreTargets + testTargets
)
