// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DemoApp",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "DemoGallery", targets: ["DemoGallery"]),
    ],
    dependencies: [
        .package(path: "../../"),
    ],
    targets: [
        .target(
            name: "DemoKit",
            dependencies: [
                .product(name: "SnapPreferences", package: "Snap"),
            ]),
        .executableTarget(
            name: "DemoGallery",
            dependencies: [
                "DemoKit",
                .product(name: "SnapGallery", package: "Snap"),
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
