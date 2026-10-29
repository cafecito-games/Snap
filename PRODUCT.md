# Product

<!-- impeccable:product-schema 1 -->

## Platform

macOS

## Users

Snap serves Swift and SwiftUI engineers working in Xcode on macOS. They use
existing Xcode previews as executable component examples, snapshot fixtures,
and a way to inspect UI states without maintaining a parallel story format.

The native gallery is intended for those engineers and trusted internal
reviewers who need to browse the compiled previews available in a development
build.

## Product Purpose

Snap discovers compiled SwiftUI previews and turns them into useful development
artifacts: XCTest cases, rendered snapshots, metadata exports, and a native
component gallery. Success means a preview remains the single source of truth
for Xcode, tests, exported images, and gallery browsing.

## Positioning

Snap derives its catalog directly from `#Preview` and `PreviewProvider` runtime
metadata. Consumers do not maintain separate snapshot tests or story files.

## Operating Context

Snap is integrated through Swift Package Manager and used from Xcode, SwiftPM
test runs, macOS CI, and trusted internal macOS applications. Gallery previews
must be compiled and linked into the gallery host process to be discoverable.

## Capabilities and Constraints

- macOS 15 or newer, Swift 6 mode, and an Xcode 26-compatible toolchain.
- SwiftUI previews only; runtime discovery covers `#Preview` and
  `PreviewProvider` declarations.
- The native gallery is a reusable SwiftUI library product, not a standalone
  process capable of loading arbitrary unrelated application modules.
- Existing previews remain the story-authoring API. Automatic component
  property controls are outside the initial scope.
- The gallery is for Debug or trusted internal builds because previews can
  include unfinished UI and development data and may be removed by optimized
  builds.

## Brand Commitments

The product name is Snap. Public APIs use concise `Snap`-prefixed product names
and standard Swift API design. The voice is direct, technical, and economical.

## Evidence on Hand

- Runtime discovery and preview models in `Sources/SnapCore`.
- AppKit snapshot rendering and metadata preference capture in
  `Sources/SnapCore` and `Sources/SnapPreferences`.
- A four-preview sample component module in `Examples/DemoApp`.
- XCTest and export coverage in `Tests/SnapTestsTests`.
- No established gallery visual system or gallery screenshots exist yet.

## Product Principles

- Use previews as the single source of truth.
- Keep gallery integration additive and separate from XCTest.
- Preserve narrow target boundaries and avoid exposing runtime internals.
- Prefer native macOS interaction and accessibility conventions.
- Keep large preview catalogs responsive through lazy, isolated rendering.

## Accessibility & Inclusion

The gallery must support keyboard navigation, VoiceOver labels, system text
styles, reduced-motion preferences, and sufficient contrast in both system
appearances.

## Assumptions

This product record was inferred from the repository documentation and the
explicit request to build a native Storybook-style `SnapGallery`. Audience and
scope can be revised when broader distribution requirements are established.
