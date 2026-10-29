# Snap

📸 Snapshot every Xcode preview on macOS — with zero test code.

Snap discovers the SwiftUI previews in your built modules (`#Preview` macros
and `PreviewProvider` types), turns each one into a real XCTest method, renders
it offscreen, and either attaches the PNG to the test result or writes it to
disk for visual-diff tooling such as [Sentry Snapshots][sentry].

Snap is a macOS-only reimplementation of [SnapshotPreviews][upstream]
(see `LICENSE` for attribution), rebuilt as a pure source package for the
needs of the UzirEdit project.

## Installation

Add the package to your project:

```swift
.package(url: "https://github.com/CafecitoGames/Snap", from: "0.1.0")
```

Link your **XCTest target** to the `SnapTests` product. Link the target that
**declares the previews** (usually your app or framework target) to
`SnapPreferences` if you want per-preview customization.

## Generating snapshots

Create one test class that inherits from `SnapTest`. There are no test methods
to write — they are generated at runtime, one per discovered preview:

```swift
import SnapTests
import EditorWorkspace

final class EditorWorkspacePreviewTests: SnapTest {
    // Optional: render only previews whose names match these regex patterns.
    // `nil` renders every preview.
    override class func includedPreviews() -> [String]? {
        nil
    }

    // Optional: exclude previews whose names match these regex patterns.
    override class func excludedPreviews() -> [String]? {
        nil
    }

    // Optional: restrict discovery to these modules.
    override class func includedModules() -> [String]? {
        ["EditorWorkspace"]
    }

    // Optional: exclude these modules from discovery.
    override class func excludedModules() -> [String]? {
        nil
    }
}
```

Run the test class in Xcode and each preview appears as a test with its PNG
attached to the result bundle.

`#Preview` previews are named `Module/File.swift:Display Name`; previews from
`PreviewProvider` types are named by their fully-qualified type name. Both
forms match as regular expressions in the filters above.

### Layout-only checks

Inherit from `SnapLayoutTest` instead of `SnapTest` to lay out every preview
without capturing pixels. It runs much faster and still catches crashes such
as a missing `@EnvironmentObject`, giving you preview coverage without image
cost.

## Exporting snapshots for CI

By default each rendered preview is attached to the `.xcresult` bundle as a
PNG. To write the images (plus JSON metadata sidecars) to a directory instead,
set `SNAPSHOTS_EXPORT_DIR` on the test invocation:

```shell
TEST_RUNNER_SNAPSHOTS_EXPORT_DIR="$PWD/snapshot-images" \
xcodebuild test \
  -scheme MyApp \
  -destination 'platform=macOS'
```

The `TEST_RUNNER_` prefix is how `xcodebuild` forwards an environment variable
into the test runner process; Snap reads the variable without the prefix. For
every rendered preview two files are written:

- `<name>.png` — the rendered preview image.
- `<name>.json` — metadata sidecar:

| Field | Description |
| --- | --- |
| `display_name` | Snapshot name shown downstream. |
| `group` | Grouping key derived from the declaring file or type. |
| `diff_threshold` | Allowed visual difference, from `.snapDiffThreshold(...)`. |
| `tags` | Key-value tags, from `.snapTags(...)`. |
| `context` | Test name, preview metadata, and any custom context. |

The sidecar format matches what `sentry-cli build snapshots` expects:

```shell
sentry-cli build snapshots "$PWD/snapshot-images" \
  --auth-token "$SENTRY_AUTH_TOKEN" \
  --app-id com.example.MyApp \
  --project my-mac-project
```

### Listing image names without rendering

For selective-testing workflows, set `SNAPSHOTS_ALL_IMAGE_NAMES_FILE` to write
the logical `.png` file names of every discovered preview to a file, skipping
rendering entirely. This mode is mutually exclusive with
`SNAPSHOTS_EXPORT_DIR`.

## Customizing previews

Link the target that declares your previews to `SnapPreferences` and annotate
individual previews:

```swift
import SnapPreferences

#Preview("Map") {
    MapPreview()
        .snapTags(["screen": "map"])
        .snapAdditionalContext(["fixture": "city-route"])
        .snapDiffThreshold(0.05)
        .snapRenderingMode(.layer)
}
```

| Modifier | Effect |
| --- | --- |
| `.snapDiffThreshold(0.05)` | Allows up to 5% changed pixels before the image is flagged downstream. |
| `.snapTags(["area": "checkout"])` | Adds searchable tags to the sidecar. Repeated modifiers merge; later keys win. |
| `.snapAdditionalContext(["fixture": "loaded"])` | Adds fields to the sidecar `context` object. Supported values: strings, booleans, finite numbers, and nested dictionaries. Custom keys override generated ones. |
| `.snapRenderingMode(.layer)` | Captures through the layer tree instead of `NSView.cacheDisplay` when the default path mis-renders content. |

## Tips

- **Give every preview a unique display name.** The name becomes the test
  name, the exported file name, and the sidecar `display_name`.
- **Keep previews deterministic.** Avoid live network calls, timers,
  animations that never settle, and clock-derived dates, so the same preview
  produces the same pixels everywhere.
- **Detect the snapshot environment** in your app code with a single check:

  ```swift
  extension ProcessInfo {
      var isRunningSnapshots: Bool {
          environment["SNAPSHOTS_RUNNING_FOR_PREVIEWS"] == "1"
      }
  }
  ```

  Set `SNAPSHOTS_RUNNING_FOR_PREVIEWS=1` in the scheme that runs your Snap
  tests, and disable preview-unfriendly behavior (logging, analytics,
  networking) while it is set.

## How it works

Snap scans the `__swift5_proto` sections of the images loaded in the test
process for protocol conformances to SwiftUI's `PreviewProvider` and
DeveloperToolsSupport's `PreviewRegistry` (the protocol the `#Preview` macro
expands to). For each conformance it reconstructs the declaring type, walks
the runtime metadata to reach the preview's view, renders it in an offscreen
`NSHostingController`, and captures the pixels.

`PreviewProvider` declares several children in `static var previews`; Snap
selects each child individually through SwiftUI's variadic view tree.
`#Preview` bodies live behind SPI types that are not visible to source
compilation, so Snap extracts the view through runtime reflection instead.

Rendering happens inside the normal XCTest process — no host application
required — which is what makes the package work for plain unit-test bundles.

## Scope and limitations

- macOS only, SwiftUI previews only (`#Preview` and `PreviewProvider`).
  Previews that wrap `NSView` content are not rendered.
- The window-capture rendering mode from SnapshotPreviews is not ported:
  the API it used (`CGWindowListCreateImage`) was obsoleted in macOS 15, and
  its replacement (ScreenCaptureKit) requires asynchronous capture and screen
  recording permissions.
- Accessibility overlays, the in-app Preview Gallery, and the inserted-dylib
  accessibility test flow from SnapshotPreviews are not ported.

## Development

```shell
xcrun swift test          # unit tests + end-to-end fixture rendering
SNAPSHOTS_EXPORT_DIR=/tmp/snap-export xcrun swift test   # exercise the export flow
```

### Troubleshooting: `plugin for module 'PreviewsMacros' not found`

Always build with `xcrun swift ...`, not bare `swift`. The `#Preview` macro
plugin (`PreviewsMacros`) ships inside Xcode's platform directory — it is not
part of the command-line tools or standalone toolchains such as swiftly. If
`swift test` fails with

```
external macro implementation type 'PreviewsMacros.SwiftUIView' could not be
found for macro 'Preview(_:body:)'; plugin for module 'PreviewsMacros' not found
```

your PATH resolves `swift` to a standalone toolchain (check with
`which -a swift`). Run `xcrun swift test`, which selects the active Xcode
toolchain via `xcode-select`, or switch that shell to Xcode's toolchain.

[sentry]: https://docs.sentry.io/product/snapshots/
[upstream]: https://github.com/getsentry/SnapshotPreviews
