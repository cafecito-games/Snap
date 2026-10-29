---
version: 1
slug: "sources-snapgallery-snapgallery-swift"
primary_target: "Sources/SnapGallery/SnapGallery.swift"
related_targets: ["Sources/SnapGallery"]
---

# Snap Gallery Surface

Mode: Operate.

Audience: SwiftUI engineers and trusted internal reviewers browsing compiled
previews. The frequent task is to find a component state quickly, inspect it at
useful scale, interact with a fresh instance, and understand its provenance.

## Direction contract

THESIS: Snap Gallery is a native proofing table: the component specimen owns the
room while navigation and metadata recede. It refuses dashboard card grids and
browser-shaped Storybook imitation.

OWN-WORLD: Cool system neutrals, graphite text, one system-blue selection state,
hairline dividers, compact SF typography, square native controls, and a white or
checkerboard proofing field. Density comes from alignment rather than decoration.

STORY: Select a module, scan its named component states, open one live preview,
adjust the canvas, then read source and captured metadata without leaving the
workspace.

FIRST VIEWPORT: A three-column macOS split view fills the window. Modules and
groups occupy the compact sidebar, stories form a narrow contact sheet, and the
live canvas takes most of the width. A trailing inspector can be shown without
covering the specimen. The toolbar carries only canvas operations.

FORM: Print-proofing desk, seventh grounded direction from seed 3d6c042a. The
signature interaction is selecting a contact-sheet row and replacing the live
specimen with a fresh instance while canvas framing stays stable.

FINISH: unreviewed and undocumented is unfinished; this build ends with the
finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance

Constraints: macOS 15+, Swift 6, native SwiftUI controls, keyboard and VoiceOver
support, lazy thumbnail work, no second story-authoring API, no shipping raster
assets.
