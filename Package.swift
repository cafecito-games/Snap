// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Snap",
    platforms: [
        .macOS(.v15),
        .iOS("26.0"),
    ],
    products: [
        // Link this product to your XCTest target.
        .library(name: "SnapTests", targets: ["SnapTests"]),
        // Link this product to your app or framework target to customize
        // individual previews (diff threshold, tags, rendering mode, metadata).
        .library(name: "SnapPreferences", targets: ["SnapPreferences"]),
        // Shared value types exposed through the products above.
        .library(name: "SnapModels", targets: ["SnapModels"]),
        // Link this product to a trusted internal macOS app to browse its
        // compiled SwiftUI previews in a native component gallery.
        .library(name: "SnapGallery", targets: ["SnapGallery"]),
        // Preview discovery and rendering internals, exposed for binary
        // distribution builds.
        .library(name: "SnapCore", targets: ["SnapCore"]),
        // Objective-C runtime support, exposed for binary distribution builds.
        .library(name: "SnapTestSupport", targets: ["SnapTestSupport"]),
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
            name: "SnapGallery",
            dependencies: [
                "SnapCore",
                "SnapModels",
                "SnapPreferences",
            ]),
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
            dependencies: ["SnapTests", "SnapCore", "SnapGallery", "SnapPreferences"]),
    ],
    swiftLanguageModes: [.v6],
)
