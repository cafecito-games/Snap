#!/usr/bin/env bash
# Builds each shippable target as a macOS XCFramework with library evolution
# enabled, so the binaries load under any consumer toolchain.
#
# Usage: Scripts/build-xcframeworks.sh [output-directory]
#
# Xcode 26 emits SPM products as bare object files plus swiftmodule
# directories rather than frameworks, so this script assembles proper
# framework bundles itself: each object is linked into a dylib (in dependency
# order, so inter-module autolinking resolves), bundled with its module
# interfaces, and wrapped into an XCFramework.
#
# Interface verification is disabled during the build because XCTest-based
# module interfaces do not round-trip under the verifier; the interfaces are
# then sanitized (see sanitize_module) so consumers can compile against them.
# Requires Xcode; run from the repository root.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST_DIR="${1:-$REPO_ROOT/dist}"
BUILD_DIR="$(mktemp -d)"
DERIVED_DATA="$BUILD_DIR/DerivedData"
FRAMEWORKS_DIR="$BUILD_DIR/frameworks"
PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Release"

# Universal binaries cover both macOS architectures in one slice.
ARCHS_SETTING="arm64 x86_64"
# XCTest ships inside the platform's Developer directory rather than the
# platform SDK itself; its Swift support library sits in the adjacent usr/lib.
PLATFORM_DEVELOPER_DIR="$(xcrun --sdk macosx --show-sdk-platform-path)/Developer"
XCODE_LIB_FRAMEWORKS="$PLATFORM_DEVELOPER_DIR/Library/Frameworks"
XCODE_LIB_DIR="$PLATFORM_DEVELOPER_DIR/usr/lib"

# Linked in this order; each framework links against the frameworks built
# before it. Dependency lists are explicit because the autolink entries SPM
# records for package dependencies do not resolve through -F search paths.
declare -a LINK_DEPENDENCIES=(
    "SnapModels|"
    "SnapTestSupport|"
    "SnapCore|-framework SnapModels"
    "SnapPreferences|-framework SnapModels"
    "SnapTests|-framework SnapCore -framework SnapModels -framework SnapTestSupport"
)

mkdir -p "$DIST_DIR" "$FRAMEWORKS_DIR"
rm -rf "$DIST_DIR"/*.xcframework "$DIST_DIR"/*.zip "$DIST_DIR/checksums.txt"

# Building the two leaf schemes transitively builds every shippable target.
for scheme in "SnapTests" "SnapPreferences"; do
    echo "==> Building $scheme"
    xcodebuild build \
        -scheme "$scheme" \
        -configuration "Release" \
        -destination 'generic/platform=macOS' \
        -derivedDataPath "$DERIVED_DATA" \
        ARCHS="$ARCHS_SETTING" \
        ONLY_ACTIVE_ARCH=NO \
        BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
        OTHER_SWIFT_FLAGS="-no-verify-emitted-module-interface" \
        -quiet
done

write_info_plist() {
    local path="$1"
    local name="$2"
    cat > "$path" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${name}</string>
    <key>CFBundleIdentifier</key>
    <string>games.cafecito.${name}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${name}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
</dict>
</plist>
PLIST
}

# XCTest is not a library-evolution framework, so module interfaces that
# reference it fail to parse unless the references are unqualified — which
# resolves correctly for consumers, whose test bundles always import XCTest.
# Self-qualified type names are likewise rewritten to plain names.
sanitize_module() {
    local module_dir="$1"
    local framework="$2"
    find "$module_dir" -name "*.private.swiftinterface" -delete
    find "$module_dir" -name "*.package.swiftinterface" -delete
    find "$module_dir" -name "*.swiftinterface" | while read -r file; do
        sed \
            -e '/NSInvocation/d' \
            -e 's/XCTest\.//g' \
            -e "s/${framework}\.//g" \
            "$file" > "$file.tmp"
        mv "$file.tmp" "$file"
    done
}

verify_framework_signature() {
    local framework_path="$1"
    codesign --verify --deep --strict --verbose=2 "$framework_path"
}

for entry in "${LINK_DEPENDENCIES[@]}"; do
    framework="${entry%%|*}"
    dependency_flags="${entry#*|}"
    OBJECT_FILE="$PRODUCTS_DIR/$framework.o"
    if [ ! -f "$OBJECT_FILE" ]; then
        echo "error: build did not produce $OBJECT_FILE" >&2
        exit 1
    fi

    echo "==> $framework: assembling framework"
    FRAMEWORK_PATH="$FRAMEWORKS_DIR/$framework.framework"
    VERSION_A="$FRAMEWORK_PATH/Versions/A"
    mkdir -p "$VERSION_A/Resources" "$VERSION_A/Modules"

    case "$framework" in
        SnapTests)
            dependency_flags="$dependency_flags -framework XCTest -lXCTestSwiftSupport"
            ;;
    esac

    # Link the dylib with Xcode's toolchain and SDK; the command-line tools'
    # SDK rejects framework clients of SwiftUI's support libraries. XCTest
    # lives outside the platform SDK, so its path is passed with -iframework.
    # shellcheck disable=SC2086
    xcrun --sdk macosx clang -dynamiclib \
        "$OBJECT_FILE" \
        $dependency_flags \
        -o "$VERSION_A/$framework" \
        -install_name "@rpath/$framework.framework/Versions/A/$framework" \
        -isysroot "$(xcrun --sdk macosx --show-sdk-path)" \
        -F "$FRAMEWORKS_DIR" \
        -F "$XCODE_LIB_FRAMEWORKS" \
        -iframework "$XCODE_LIB_FRAMEWORKS" \
        -L "$XCODE_LIB_DIR"

    if [ "$framework" = "SnapTestSupport" ]; then
        mkdir -p "$VERSION_A/Headers"
        cp "$REPO_ROOT/Sources/SnapTestSupport/include/SnapTestSupport.h" \
            "$VERSION_A/Headers/"
        cat > "$VERSION_A/Modules/module.modulemap" <<'MODULEMAP'
framework module SnapTestSupport {
    header "../Headers/SnapTestSupport.h"
    export *
}
MODULEMAP
    else
        cp -R "$PRODUCTS_DIR/$framework.swiftmodule" \
            "$VERSION_A/Modules/$framework.swiftmodule"
        sanitize_module "$VERSION_A/Modules/$framework.swiftmodule" "$framework"
    fi

    write_info_plist "$VERSION_A/Resources/Info.plist" "$framework"

    ln -shf A "$FRAMEWORK_PATH/Versions/Current"
    ln -shf "Versions/Current/$framework" "$FRAMEWORK_PATH/$framework"
    ln -shf Versions/Current/Resources "$FRAMEWORK_PATH/Resources"
    ln -shf Versions/Current/Modules "$FRAMEWORK_PATH/Modules"
    if [ -d "$VERSION_A/Headers" ]; then
        ln -shf Versions/Current/Headers "$FRAMEWORK_PATH/Headers"
    fi

    # Linking leaves an ad-hoc Mach-O signature without a framework resource
    # envelope. Sign the completed bundle so its Info.plist, modules, and
    # versioned-framework symlinks are all covered by a valid signature.
    echo "==> $framework: signing framework"
    codesign --force --sign - --timestamp=none "$FRAMEWORK_PATH"
    verify_framework_signature "$FRAMEWORK_PATH"

    echo "==> $framework: creating XCFramework"
    xcodebuild -create-xcframework \
        -framework "$FRAMEWORK_PATH" \
        -output "$DIST_DIR/$framework.xcframework"

    while IFS= read -r -d '' packaged_framework; do
        # create-xcframework omits architecture-specific compiled module
        # files from library-evolution frameworks, so seal the copied bundle
        # after Xcode has finalized its packaged contents.
        codesign --force --sign - --timestamp=none "$packaged_framework"
        verify_framework_signature "$packaged_framework"
    done < <(find "$DIST_DIR/$framework.xcframework" \
        -type d -name "*.framework" -print0)

    echo "==> $framework: zipping"
    # -y stores symbolic links as links instead of materializing their targets.
    (cd "$DIST_DIR" && zip -qry "$framework.xcframework.zip" "$framework.xcframework")
    rm -rf "$DIST_DIR/$framework.xcframework"
done

echo "==> Checksums"
for zip in "$DIST_DIR"/*.xcframework.zip; do
    name="$(basename "$zip")"
    checksum="$(swift package compute-checksum "$zip")"
    shasum_checksum="$(shasum -a 256 "$zip" | awk '{print $1}')"
    if [ "$checksum" != "$shasum_checksum" ]; then
        echo "error: SwiftPM and shasum checksums differ for $name" >&2
        exit 1
    fi
    printf '%s  %s\n' "$checksum" "$name" | tee -a "$DIST_DIR/checksums.txt"
done
(cd "$DIST_DIR" && shasum -a 256 -c checksums.txt)

echo "==> Done: $DIST_DIR"
