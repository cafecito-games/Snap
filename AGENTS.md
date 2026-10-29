# Repository Guidelines

## Project Structure & Module Organization

Snap is a macOS-only Swift Package Manager library. `Package.swift` defines the public `SnapTests`, `SnapPreferences`, and `SnapModels` products and requires macOS 15 and Swift 6 mode.

- `Sources/SnapCore/`: preview discovery, metadata scanning, and AppKit rendering internals.
- `Sources/SnapTests/`: XCTest integration, snapshot naming, and export coordination.
- `Sources/SnapPreferences/` and `Sources/SnapModels/`: public customization APIs and shared value types.
- `Sources/SnapTestSupport/`: Objective-C runtime support and public headers.
- `Tests/SnapTestsTests/`: XCTest coverage and preview fixtures.
- `.github/workflows/ci.yml`: macOS CI configuration.

Keep implementation in the narrowest appropriate target and avoid exposing `SnapCore` details through public APIs.

## Build, Test, and Development Commands

Run commands from the repository root:

```sh
xcrun swift build
xcrun swift test
SNAPSHOTS_EXPORT_DIR=/tmp/snap-export xcrun swift test
```

`swift build` compiles all package targets. `swift test` runs the unit tests and end-to-end fixture rendering used by CI. The export variant also exercises PNG and JSON sidecar output. Use Xcode 26 or a compatible Swift 6.2 toolchain; rendering requires macOS.

## Coding Style & Naming Conventions

Follow standard Swift API design: four-space indentation, opening braces on the declaration line, trailing commas in multiline argument lists, and descriptive lower-camel-case members. Use UpperCamelCase for types and protocols. Keep files focused and name them after their primary type, such as `PreviewDiscovery.swift`. Preserve actor annotations (`@MainActor`) around UI and rendering code. Add documentation comments to public APIs and to runtime logic whose intent is not obvious. No formatter or linter is currently configured; match surrounding code and keep builds warning-free.

## Testing Guidelines

Tests use XCTest. Add cases under `Tests/SnapTestsTests/` in files ending with `Tests.swift`; name methods `test...` and state the expected behavior, for example `testSanitizeTrimsLeadingAndTrailingSeparators`. Reuse `Fixtures.swift` for preview discovery and rendering scenarios. Every behavior change should include a focused regression test. Run the complete test suite before submitting changes; no numeric coverage threshold is enforced.

## Commit & Pull Request Guidelines

The history currently uses a concise, imperative subject with a component prefix, for example `Snap: macOS preview snapshotting as a pure source package`. Keep commits focused and avoid mixing refactors with behavior changes. Pull requests should explain the motivation, summarize implementation and testing, and link relevant issues. Include sample exported filenames, metadata, or screenshots when snapshot output changes. Ensure the macOS CI test job passes before requesting review.
