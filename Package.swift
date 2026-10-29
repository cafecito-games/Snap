// swift-tools-version: 6.2
// Auto-generated for release v0.0.3 by Scripts/generate-binary-manifest.sh.
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
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.3/SnapModels.xcframework.zip",
            checksum: "07b5d99ba10a2bffd1c850d14a273a8a12fbf4044ed45dbf5e41264a282b1afa"
        ),
        .binaryTarget(
            name: "SnapCore",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.3/SnapCore.xcframework.zip",
            checksum: "2873228f35a617c4f94734701e1ca6d4a454cb62dcd9c9f91ab00fe1ad508196"
        ),
        .binaryTarget(
            name: "SnapPreferences",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.3/SnapPreferences.xcframework.zip",
            checksum: "3915af28cb57a98f0f883fd5e6aabbfad7a93806d94317c045aca71515047376"
        ),
        .binaryTarget(
            name: "SnapTestSupport",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.3/SnapTestSupport.xcframework.zip",
            checksum: "580ba865826294cb299e016649ea95fb0b4f7c7cf5e8225f016a1b390e5b52e1"
        ),
        .binaryTarget(
            name: "SnapTests",
            url: "https://github.com/cafecito-games/Snap/releases/download/v0.0.3/SnapTests.xcframework.zip",
            checksum: "3bd580c4ab2408a031b2b442631d67c01bfd139a5786f9ca68ce7d0465a8d281"
        )
    ]
)
