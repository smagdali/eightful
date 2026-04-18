// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StepsToEightCore",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .macOS(.v13),
    ],
    products: [
        .library(name: "StepsToEightCore", targets: ["StepsToEightCore"]),
    ],
    targets: [
        .target(name: "StepsToEightCore"),
        .testTarget(name: "StepsToEightCoreTests", dependencies: ["StepsToEightCore"]),
    ]
)
