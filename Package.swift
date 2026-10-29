// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Snap",
    platforms: [.macOS(.v15)],
    products: [
        // Link this product to your XCTest target.
        .library(name: "SnapTests", targets: ["SnapTests"]),
        // Link this product to your app or framework target to customize
        // individual previews (diff threshold, tags, rendering mode, metadata).
        .library(name: "SnapPreferences", targets: ["SnapPreferences"]),
        // Shared value types exposed through the products above.
        .library(name: "SnapModels", targets: ["SnapModels"]),
    ],
    targets: [
        .target(name: "SnapModels"),
        .target(
            name: "SnapCore",
            dependencies: ["SnapModels"]),
        .target(
            name: "SnapPreferences",
            dependencies: ["SnapModels"]),
        .target(
            name: "SnapTestSupport",
            publicHeadersPath: "include"),
        .target(
            name: "SnapTests",
            dependencies: [
                "SnapCore",
                "SnapModels",
                "SnapTestSupport",
            ]),
        .testTarget(
            name: "SnapTestsTests",
            dependencies: ["SnapTests", "SnapCore", "SnapPreferences"]),
    ],
    swiftLanguageModes: [.v6],
)
