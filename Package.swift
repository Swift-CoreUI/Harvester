// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harvester",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "Harvester", targets: ["Harvester"]),
        .library(name: "XCTestHarvester", targets: ["XCTestHarvester"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Harvester",
            dependencies: []),
        .target(
            name: "XCTestHarvester",
            dependencies: []),
        .testTarget(
            name: "HarvesterTests",
            dependencies: ["Harvester", "XCTestHarvester"]),
    ]
)
