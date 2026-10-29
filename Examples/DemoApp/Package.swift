// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DemoApp",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .target(
            name: "DemoKit",
            dependencies: [
                .product(name: "SnapPreferences", package: "Snap"),
            ]),
        .testTarget(
            name: "DemoKitPreviewTests",
            dependencies: [
                "DemoKit",
                .product(name: "SnapTests", package: "Snap"),
            ]),
    ],
    swiftLanguageModes: [.v6],
)
