#!/usr/bin/env bash
# Verifies a freshly built set of XCFrameworks by consuming them exactly the
# way the published binary distribution is consumed: a stand-in binary
# package plus a consumer that runs the DemoApp preview tests against the
# prebuilt frameworks. Fails unless every fixture preview renders to disk.
#
# Usage: Scripts/verify-binary-distribution.sh <dist-dir>

set -euo pipefail

DIST_DIR="${1:?usage: verify-binary-distribution.sh <dist-dir>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY_ROOT="$(mktemp -d)/binary-verify"

mkdir -p "$VERIFY_ROOT/SnapBinary" "$VERIFY_ROOT/Consumer"

# The stand-in mirrors the manifest Scripts/generate-binary-manifest.sh
# publishes; frameworks are consumed from the local build output.
mkdir -p "$VERIFY_ROOT/SnapBinary/Frameworks"
for zip in "$DIST_DIR"/*.xcframework.zip; do
    unzip -q "$zip" -d "$VERIFY_ROOT/SnapBinary/Frameworks"
done

cat > "$VERIFY_ROOT/SnapBinary/Package.swift" <<'MANIFEST'
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Snap",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "SnapTests", targets: ["SnapTests", "SnapCore", "SnapTestSupport", "SnapModels"]),
        .library(name: "SnapPreferences", targets: ["SnapPreferences", "SnapModels"]),
        .library(name: "SnapModels", targets: ["SnapModels"]),
        .library(name: "SnapCore", targets: ["SnapCore", "SnapModels"]),
        .library(name: "SnapTestSupport", targets: ["SnapTestSupport"]),
    ],
    targets: [
        .binaryTarget(name: "SnapModels", path: "Frameworks/SnapModels.xcframework"),
        .binaryTarget(name: "SnapCore", path: "Frameworks/SnapCore.xcframework"),
        .binaryTarget(name: "SnapPreferences", path: "Frameworks/SnapPreferences.xcframework"),
        .binaryTarget(name: "SnapTestSupport", path: "Frameworks/SnapTestSupport.xcframework"),
        .binaryTarget(name: "SnapTests", path: "Frameworks/SnapTests.xcframework"),
    ]
)
MANIFEST

cp -R "$REPO_ROOT/Examples/DemoApp/Sources" "$VERIFY_ROOT/Consumer/Sources"
cp -R "$REPO_ROOT/Examples/DemoApp/Tests" "$VERIFY_ROOT/Consumer/Tests"
cat > "$VERIFY_ROOT/Consumer/Package.swift" <<'MANIFEST'
// swift-tools-version: 6.2
import PackageDescription

// A path dependency's identity is its directory name, so the stand-in is
// referenced as "SnapBinary" where GitHub consumers would write "Snap".
let package = Package(
    name: "Consumer",
    platforms: [.macOS(.v15)],
    dependencies: [.package(path: "../SnapBinary")],
    targets: [
        .target(
            name: "DemoKit",
            dependencies: [.product(name: "SnapPreferences", package: "SnapBinary")]),
        .testTarget(
            name: "DemoKitPreviewTests",
            dependencies: [
                "DemoKit",
                .product(name: "SnapTests", package: "SnapBinary"),
            ]),
    ],
    swiftLanguageModes: [.v6],
)
MANIFEST

EXPORT_DIR="$VERIFY_ROOT/exported"
echo "==> Running consumer preview tests against the binary distribution"
(cd "$VERIFY_ROOT/Consumer" && SNAPSHOTS_EXPORT_DIR="$EXPORT_DIR" xcrun swift test)

IMAGE_COUNT="$(ls "$EXPORT_DIR" 2>/dev/null | grep -c '\.png$')"
if [ "$IMAGE_COUNT" -lt 4 ]; then
    echo "error: expected at least 4 exported snapshots from the binary distribution, found $IMAGE_COUNT" >&2
    exit 1
fi
echo "==> Binary distribution verified: $IMAGE_COUNT snapshots rendered"
