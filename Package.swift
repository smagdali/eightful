// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EightfulCore",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9),
        .macOS(.v13),
    ],
    products: [
        .library(name: "EightfulCore", targets: ["EightfulCore"]),
    ],
    targets: [
        .target(name: "EightfulCore"),
        .testTarget(name: "EightfulCoreTests", dependencies: ["EightfulCore"]),
    ]
)
