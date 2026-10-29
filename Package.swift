// swift-tools-version: 6.2
// Auto-generated for release v0.0.2 by Scripts/generate-binary-manifest.sh.
// Do not edit by hand; the binary branch is republished by the release
// pipeline.

import PackageDescription

let package = Package(
    name: "Snap",
    platforms: [.macOS(.v15)],
    products: [
        // Binary targets cannot express dependencies on each other, so every
        // product bundles the frameworks it needs to link and load.
        .library(
            name: "SnapTests",
            targets: ["SnapTests", "SnapCore", "SnapTestSupport", "SnapModels"]),
        .library(
            name: "SnapPreferences",
            targets: ["SnapPreferences", "SnapModels"]),
        .library(name: "SnapModels", targets: ["SnapModels"]),
        .library(name: "SnapCore", targets: ["SnapCore", "SnapModels"]),
        .library(name: "SnapTestSupport", targets: ["SnapTestSupport"]),
    ],
    targets: [
        .binaryTarget(
            name: "SnapModels",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.2/SnapModels.xcframework.zip",
            checksum: "b00369add07e00f60f4bc556c741785e067d5e3d6fe7a683c5e103c62100bbfd"
        ),
        .binaryTarget(
            name: "SnapCore",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.2/SnapCore.xcframework.zip",
            checksum: "6af1a48a89df8f1ddb225962bc6bf49e961ed123f2e37a854e13a474ccfc2769"
        ),
        .binaryTarget(
            name: "SnapPreferences",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.2/SnapPreferences.xcframework.zip",
            checksum: "263e82905377f60e4c66b5161003399db7da3f9740e10dd410f9f0e608ca16bc"
        ),
        .binaryTarget(
            name: "SnapTestSupport",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.2/SnapTestSupport.xcframework.zip",
            checksum: "03aae887ab76222a8f8cfbb921048692fdb3489bfd9f2f96eb17b07fe1d0968f"
        ),
        .binaryTarget(
            name: "SnapTests",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.2/SnapTests.xcframework.zip",
            checksum: "2dd6aef55cde3814a3c70a1b9a7ef54af5b60990dcfcb2c8db4cb96c0e3177d6"
        )
    ]
)
