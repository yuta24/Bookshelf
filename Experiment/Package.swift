// swift-tools-version: 5.10

import PackageDescription

extension String {
    static let Functional = "Functional"
    static let HotComponent = "HotComponent"
    static let Network = "Network"
    static let RemoteUI = "RemoteUI"
}

let package = Package(
    name: "Experiment",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: .Functional, targets: [.Functional]),
        .library(name: .HotComponent, targets: [.HotComponent]),
        .library(name: .Network, targets: [.Network]),
        .library(name: .RemoteUI, targets: [.RemoteUI]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzysztofzablocki/KZFileWatchers.git", branch: "master"),
    ],
    targets: [
        .target(
            name: .Functional,
            dependencies: []
        ),
        .target(
            name: .HotComponent,
            dependencies: [
                .product(name: "KZFileWatchers", package: "KZFileWatchers"),
            ]
        ),
        .target(
            name: .Network,
            dependencies: []
        ),
        .target(
            name: .RemoteUI,
            dependencies: [
                .product(name: "KZFileWatchers", package: "KZFileWatchers"),
            ]
        ),
    ]
)
