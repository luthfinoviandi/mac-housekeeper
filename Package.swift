// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MacHousekeeper",
    platforms: [
        .macOS("15.0")
    ],
    products: [
        .executable(
            name: "mac-housekeeper",
            targets: ["MacHousekeeper"]
        ),
        .executable(
            name: "MacHousekeeperApp",
            targets: ["MacHousekeeperApp"]
        )
    ],
    targets: [
        .target(
            name: "MacHousekeeperCore"
        ),
        .executableTarget(
            name: "MacHousekeeper",
            dependencies: ["MacHousekeeperCore"]
        ),
        .executableTarget(
            name: "MacHousekeeperApp",
            dependencies: ["MacHousekeeperCore"]
        ),
        .testTarget(
            name: "MacHousekeeperTests",
            dependencies: ["MacHousekeeper", "MacHousekeeperCore", "MacHousekeeperApp"]
        )
    ]
)
