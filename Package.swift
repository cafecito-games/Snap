// swift-tools-version: 6.2
// Auto-generated for release v0.0.1 by Scripts/generate-binary-manifest.sh.
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
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.1/SnapModels.xcframework.zip",
            checksum: "d5e13059848ccade69700a9a45c3ed85fa379e3b91ca9f694dd8436beb6475c5"
        ),
        .binaryTarget(
            name: "SnapCore",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.1/SnapCore.xcframework.zip",
            checksum: "e96f1866f7f797fff1ee1a30c58cc1ace3ae99059934918ee8193579027d9045"
        ),
        .binaryTarget(
            name: "SnapPreferences",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.1/SnapPreferences.xcframework.zip",
            checksum: "75ce25b5a5463c2de2fbda03b107c9cae2361c3e680a9dfbf1465c5fdd7d33bc"
        ),
        .binaryTarget(
            name: "SnapTestSupport",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.1/SnapTestSupport.xcframework.zip",
            checksum: "348ae9b6a2dfec18a7d7208f886d5c37e260a0a0acb3354e0c85a4e59bc7d45b"
        ),
        .binaryTarget(
            name: "SnapTests",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.1/SnapTests.xcframework.zip",
            checksum: "b05b4e00fe806aa0d377b47d94c4ef31024db4340fe2e38bcf449880dceea631"
        )
    ]
)
