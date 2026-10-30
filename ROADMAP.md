# Snap Roadmap

Snap turns compiled SwiftUI previews into three views of the same component
catalog: an interactive native gallery, executable layout and snapshot tests,
and portable image metadata for visual review systems.

The roadmap is outcome-driven. A milestone is complete only when its exit
criteria are met; version numbers describe maturity rather than dates.

## Product North Star

Write a preview once, then browse it, interact with it, inspect it, snapshot
it, and compare it without maintaining a parallel story format.

Snap should feel native on every supported platform. It should adopt the
useful parts of Storybook's workflow without copying its web shell or its
component-arguments authoring model.

## Principles

- SwiftUI previews are the single source of truth.
- macOS is the primary platform and must not regress as other platforms are
  explored.
- Runtime discovery failures must be visible and actionable.
- Rendering configuration and output should be platform-neutral; AppKit and
  UIKit are backends.
- Gallery integration remains additive and separate from XCTest.
- Prefer native navigation, keyboard, accessibility, and interaction
  conventions on each platform.
- Large catalogs must remain responsive through lazy, isolated, prioritized
  rendering.
- Keep unsupported or experimental behavior explicit.

## Platform Tiers

### Tier 1: macOS

The complete supported experience: gallery, snapshot and layout tests,
artifact export, CI, source distribution, and binary distribution.

### Tier 2: iPadOS and iOS Simulator

Planned after the UIKit feasibility gate. The initial target is an adaptive
iPad gallery and simulator-hosted snapshot tests. iPhone uses the same UIKit
renderer with a compact navigation shell.

Snap follows a rolling two-major-version policy for iOS and iPadOS: the
current stable major and the immediately previous stable major. As of October
2026, that means iOS/iPadOS 27 and 26, with a package deployment floor of
26.0. When a new major ships, the floor advances only after its stable Xcode
toolchain is available, both supported runtimes pass CI, and the change is
announced in release notes. Before 1.0 the floor may advance in a minor
release; after 1.0, raising it requires the next major Snap release.

### Experimental: physical iOS and iPadOS devices

Useful for fidelity checks, but signing, runtime discovery, performance, and
artifact extraction must be proven before support is promised.

### Out of Scope Before 1.0

- Automatic controls generated from component properties.
- Loading arbitrary modules that are not linked into the gallery host.
- A hosted collaboration service.
- watchOS, tvOS, and visionOS.
- Screen-recording-based window capture.

## Current Baseline

- Runtime discovery of `#Preview` and `PreviewProvider` declarations.
- Dynamic XCTest generation with one test per preview.
- AppKit rendering, Xcode attachments, and PNG/JSON export.
- Per-preview tags, context, diff threshold, and rendering mode.
- A native macOS gallery with module and component navigation, story
  thumbnails, a live interactive canvas, proofing backgrounds, zoom, and an
  inspector.
- A demo component module shared by gallery and test examples.
- A platform-neutral render request, outcome, error, and bitmap contract with
  AppKit and experimental UIKit backends.
- Thirty-eight passing macOS tests plus eight passing UIKit spike tests.

## Milestones

### 0.0.4 — Trustworthy Foundation

**Outcome:** setup is coherent and every discovery or rendering failure tells
the developer what happened.

- Introduce a structured discovery report containing results, invalid
  filters, missing linked modules, skipped preview types, and compatibility
  diagnostics.
- Add explicit gallery loading, empty, degraded, and failure states.
- Audit the public API and keep runtime implementation details out of normal
  consumer-facing products.
- Reconcile README installation versions and stale limitations.
- Add fixtures for empty modules, duplicate names, malformed filters,
  unavailable previews, native representables, and extreme layouts.
- Build the example gallery in CI in addition to testing snapshot export.
- Establish the platform-neutral rendering boundary required by the UIKit
  spike.

**Exit criteria**

- A new consumer can launch a useful gallery in under ten minutes.
- An empty gallery always explains why it is empty.
- Supported discovery failures never depend only on console output.
- Source and binary distributions pass the same public behavior suite.

### 0.1 — Daily-Use macOS Gallery

**Outcome:** the gallery is pleasant and fast enough to remain open while
components are developed.

- Search individual stories, tags, component names, and modules.
- Add native commands for search, story navigation, zoom, reset, grid, and
  inspector visibility.
- Reveal a story's source in Xcode and copy its source location.
- Refresh discovery without relaunching the host.
- Persist selection, window-independent canvas settings, and inspector state.
- Copy or export the selected snapshot from the gallery.
- Add stable, linkable story identifiers.
- Replace FIFO thumbnail work with a scheduler that prioritizes the selected
  story, then visible rows, and cancels stale work.
- Add keyboard-navigation, VoiceOver, reduced-motion, and UI regression tests.

**Exit criteria**

- A catalog of 500 stories remains responsive.
- The selected story renders before background thumbnails.
- Every primary operation is available from the keyboard and has an
  accessibility label.

### UIKit Feasibility Gate

**Outcome:** decide from executable evidence whether iPadOS and iOS are viable
without weakening the macOS design.

- Build `SnapModels` and `SnapPreferences` for iOS.
- Link a fixture module containing `#Preview` declarations into an iPadOS
  simulator host and discover its preview registries at runtime.
- Render SwiftUI and `UIViewRepresentable` fixtures through a hosted UIKit
  hierarchy and export PNG data.
- Validate dynamic XCTest enumeration in an iOS Simulator unit-test bundle.
- Run the proof through `xcodebuild test` on a named simulator destination.
- Record discovered toolchain or linker constraints and make failures
  diagnostic rather than silent.

**Go criteria**

- Preview declarations survive linking and are discoverable without a
  parallel registration format.
- UIKit snapshots include UIKit and Core Animation-backed content.
- At least one generated XCTest per preview executes in the simulator.
- The macOS build and behavior suite remain unchanged.

If discovery fails the gate, Snap will keep macOS as its only runtime platform
and may later offer an explicit opt-in registration API for UIKit rather than
pretending to provide equivalent automatic discovery.

#### Spike Result — 2026-10-30

The feasibility gate passed for the iOS 26.4 Simulator with Xcode 26.4.1.

- `SnapModels`, `SnapPreferences`, `SnapCore`, `SnapTestSupport`, and
  `SnapTests` compiled for the iOS Simulator.
- Runtime discovery found linked `#Preview` and `PreviewProvider`
  declarations without an additional registration format.
- A hosted UIKit renderer captured SwiftUI and `UIViewRepresentable` content
  as PNG data and read `SnapPreferences` tags.
- `SnapTest` dynamically registered and passed one XCTest method per preview
  in an app-hosted iPad Simulator test bundle.
- The existing macOS suite remained green with all 34 tests passing.

The same Xcode 26-built fixture was also tested on an iOS 18.1 Simulator.
Legacy `PreviewProvider` discovery worked, but Xcode 26-generated `#Preview`
registries were not present through the iOS 18.1 runtime protocol path. The
experimental UIKit deployment floor is therefore iOS 26.0 until a broader
toolchain/runtime compatibility design is proven. That floor also matches the
rolling support policy's previous-major boundary now that iOS 27 is current.
This is a runtime discovery constraint, not a UIKit rendering constraint.

Still unproven: physical devices, optimized builds, artifact extraction from
simulator CI, large catalogs, a production adaptive gallery shell, and the
iOS 27 runtime under Xcode 27.

### 0.2 Experimental — iPadOS Gallery and UIKit Snapshots

**Outcome:** teams can browse and snapshot linked iOS component modules in the
iPad Simulator.

- Split platform-neutral discovery and rendering contracts from AppKit and
  UIKit backends.
- Add a `UIHostingController` and offscreen `UIWindow` renderer with view and
  layer capture modes.
- Add an adaptive iPad gallery using native split navigation, inspector, and
  hardware-keyboard commands.
- Support simulator-hosted `SnapTest` execution and PNG/JSON export through
  `xcodebuild`.
- Document the host-app and linked-module requirements.
- Add a UIKit example and simulator CI lane.

**Exit criteria**

- The same fixture catalog is discoverable in the macOS and UIKit example
  hosts where its source supports both platforms.
- Render configuration has equivalent sizing, appearance, and metadata
  semantics across backends.
- Experimental limitations are documented at the API and integration points.

### 0.3 — Proofing Environments

**Outcome:** components can be examined under realistic user environments
without creating extra story declarations.

- Add named and custom viewport sizes.
- Add appearance, Dynamic Type, locale, layout direction, accessibility
  contrast, and reduced-motion overrides.
- Allow applications to define reusable environment presets.
- Add side-by-side environment matrices such as Light × Dark or standard ×
  accessibility text size.
- Ensure the live gallery, thumbnails, and XCTest renderer share the same
  typed render configuration.

**Exit criteria**

- Equivalent render configurations produce equivalent layout and appearance
  in the gallery and snapshot tests.
- Overrides reset cleanly and never leak state between stories.

### 0.4 — Visual Review

**Outcome:** gallery browsing connects directly to the artifacts produced in
CI.

- Load baseline and current artifact directories.
- Add side-by-side, swipe, overlay, and heat-map comparisons.
- Display configured thresholds and measured differences.
- Accept individual baselines or reviewed groups through an explicit,
  recoverable workflow.
- Generate portable JSON and static HTML review reports.
- Keep the comparison layer optional so external diff services remain viable.

**Exit criteria**

- A developer can move from a failed visual change to the responsible story
  and inspect the difference without manually matching filenames.
- Baseline updates are explicit, reviewable, and never happen as a side effect
  of rendering.

### 1.0 — Stable macOS Library

**Outcome:** consumers can adopt Snap with a documented compatibility and
migration contract.

- Freeze the public authoring, discovery, rendering, and gallery APIs.
- Publish DocC documentation and complete gallery-host and CI tutorials.
- Define supported macOS, Xcode, and Swift combinations.
- Establish startup, discovery, render-latency, and memory budgets.
- Guarantee source and binary distribution parity.
- Publish a changelog, migration guide, deprecation policy, and release
  checklist.

UIKit support may remain experimental at Snap 1.0. It should graduate only
after it passes multiple Xcode/runtime compatibility cycles.

## Near-Term Issue Queue

Issues should normally be implemented in this order unless a regression or
new compatibility break takes precedence.

1. Reconcile documentation and release-version inconsistencies.
2. Add structured discovery diagnostics.
3. Add gallery loading, empty, degraded, and failure states.
4. **Complete:** Extract a platform-neutral render request and outcome model.
5. **Complete:** Complete and document the UIKit feasibility spike.
6. Add refreshable discovery and stable story identities.
7. Replace thumbnail FIFO rendering with priority scheduling.
8. Add keyboard, accessibility, and gallery interaction tests.
9. Add a large-catalog fixture and performance budgets.
10. Begin the daily-use gallery workflow milestone.

## GitHub Issue Map

### Trustworthy Foundation

- [#7 — Return structured preview discovery reports and diagnostics](https://github.com/cafecito-games/Snap/issues/7)
- [#8 — Show gallery loading, empty, degraded, and failure states](https://github.com/cafecito-games/Snap/issues/8)
- [#9 — Audit the public product surface and ten-minute onboarding path](https://github.com/cafecito-games/Snap/issues/9)
- [#10 — Add discovery edge-case fixtures and build the macOS gallery in CI](https://github.com/cafecito-games/Snap/issues/10)

### Daily-Use Gallery

- [#11 — Complete story-level and tag-aware gallery search](https://github.com/cafecito-games/Snap/issues/11)
- [#12 — Add native gallery commands, keyboard navigation, and interaction coverage](https://github.com/cafecito-games/Snap/issues/12)
- [#13 — Reveal story source in Xcode and copy its source location](https://github.com/cafecito-games/Snap/issues/13)
- [#14 — Refresh discovery without relaunching and preserve stable story identity](https://github.com/cafecito-games/Snap/issues/14)
- [#15 — Persist gallery selection and canvas preferences](https://github.com/cafecito-games/Snap/issues/15)
- [#16 — Copy or export the selected snapshot from the gallery](https://github.com/cafecito-games/Snap/issues/16)
- [#17 — Prioritize and cancel thumbnail rendering with large-catalog budgets](https://github.com/cafecito-games/Snap/issues/17)

### UIKit

- [#18 — Build an adaptive iPadOS and iPhone gallery shell](https://github.com/cafecito-games/Snap/issues/18)
- [#19 — Add UIKit simulator CI, artifact export, and shared fixture parity](https://github.com/cafecito-games/Snap/issues/19)
- [#20 — Validate physical iOS and iPadOS device feasibility](https://github.com/cafecito-games/Snap/issues/20)

### Proofing Environments

- [#21 — Add typed proofing environments and reusable presets](https://github.com/cafecito-games/Snap/issues/21)
- [#22 — Render side-by-side proofing environment matrices](https://github.com/cafecito-games/Snap/issues/22)

### Visual Review

- [#23 — Load and compare baseline/current snapshot artifact sets](https://github.com/cafecito-games/Snap/issues/23)
- [#24 — Add recoverable baseline acceptance and portable review reports](https://github.com/cafecito-games/Snap/issues/24)

### 1.0 Readiness

- [#25 — Define and enforce startup, discovery, rendering, and memory budgets](https://github.com/cafecito-games/Snap/issues/25)
- [#26 — Enforce source/binary distribution parity and library evolution](https://github.com/cafecito-games/Snap/issues/26)
- [#27 — Publish DocC, compatibility policy, migration guides, and release governance](https://github.com/cafecito-games/Snap/issues/27)

## Maintaining This Roadmap

- Update the current baseline when a milestone ships.
- Mark scope changes in the relevant milestone instead of silently expanding
  an implementation issue.
- Record important rejected approaches and compatibility findings alongside
  the milestone they affect.
- Prefer measurable exit criteria over percentage-complete estimates.
- Move completed milestone details into release notes while preserving the
  product principles and platform policy here.
