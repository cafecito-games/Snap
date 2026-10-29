#!/usr/bin/env bash
# Generates the binary-distribution Package.swift for a release tag.
#
# Usage: Scripts/generate-binary-manifest.sh <tag> <dist-dir> <output-file>
#
# Reads <dist-dir>/checksums.txt, produced by build-xcframeworks.sh, and
# writes a manifest whose targets are the prebuilt XCFrameworks attached to
# that release. Consumers who add the package from the `binary` branch get
# the same products without compiling any Swift.

set -euo pipefail

TAG="${1:?usage: generate-binary-manifest.sh <tag> <dist-dir> <output-file>}"
DIST_DIR="${2:?missing dist-dir}"
OUTPUT="${3:?missing output-file}"

BASE_URL="https://github.com/cafecito-games/Snap/releases/download/${TAG}"

checksum_for() {
    awk -v zip="$1.xcframework.zip" '$2 == zip { print $1 }' "$DIST_DIR/checksums.txt"
}

declare -a TARGETS=(
    "SnapModels"
    "SnapCore"
    "SnapPreferences"
    "SnapTestSupport"
    "SnapTests"
)

binary_target_entries=""
for target in "${TARGETS[@]}"; do
    checksum="$(checksum_for "$target")"
    if [ -z "$checksum" ]; then
        echo "error: no checksum found for $target in $DIST_DIR/checksums.txt" >&2
        exit 1
    fi
    archive="$DIST_DIR/$target.xcframework.zip"
    computed_checksum="$(swift package compute-checksum "$archive")"
    if [ "$checksum" != "$computed_checksum" ]; then
        echo "error: recorded checksum does not match $archive" >&2
        exit 1
    fi
    binary_target_entries+="        .binaryTarget(\n"
    binary_target_entries+="            name: \"$target\",\n"
    binary_target_entries+="            url: \"${BASE_URL}/${target}.xcframework.zip\",\n"
    binary_target_entries+="            checksum: \"$checksum\"\n"
    binary_target_entries+="        ),\n"
done

cat > "$OUTPUT" <<MANIFEST
// swift-tools-version: 6.2
// Auto-generated for release ${TAG} by Scripts/generate-binary-manifest.sh.
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
$(printf '%b' "$binary_target_entries" | sed '$ s/,$//')
    ]
)
MANIFEST

echo "wrote $OUTPUT"
