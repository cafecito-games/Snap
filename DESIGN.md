---
name: Snap Gallery
description: A native macOS proofing table that keeps compiled SwiftUI previews in command.
colors:
  window-background: "Canvas"
  control-background: "ButtonFace"
  text-background: "Field"
  label-primary: "CanvasText"
  label-secondary: "GrayText"
  selection-accent: "SelectedItem"
  selection-label: "SelectedItemText"
  separator: "ButtonBorder"
  proofing-canvas: "light-dark(rgb(232 232 232), rgb(33 33 33))"
  proof-white: "#ffffff"
  proof-black: "#000000"
typography:
  title:
    fontFamily: "system-ui"
    fontWeight: 600
  headline:
    fontFamily: "system-ui"
    fontWeight: 600
  body:
    fontFamily: "system-ui"
    fontWeight: 500
  label:
    fontFamily: "system-ui"
    fontWeight: 400
  numeric:
    fontFamily: "ui-monospace, SFMono-Regular, Menlo, monospace"
    fontWeight: 400
rounded:
  thumbnail: "6px"
spacing:
  compact: "4px"
  control: "8px"
  content: "12px"
  section: "16px"
  canvas-inset: "80px"
components:
  story-row:
    typography: "{typography.body}"
    padding: "5px 0"
  story-thumbnail:
    backgroundColor: "{colors.text-background}"
    rounded: "{rounded.thumbnail}"
    width: "92px"
    height: "62px"
  inspector-section:
    backgroundColor: "{colors.control-background}"
    typography: "{typography.label}"
    padding: "{spacing.section}"
---

# Design System: Snap Gallery

## Overview

**Creative North Star: "The Native Proofing Table"**

Snap Gallery is a quiet macOS workspace for examining live component specimens. Its information architecture is as direct as Storybook—catalog, stories, canvas, metadata—but its materials, density, controls, and behavior belong unmistakably to the Mac. Navigation recedes into system sidebars and lists so the selected component remains the visual hero.

The visual system is restrained and technical: dynamic system neutrals, compact SF typography, hairline structure, and one system-controlled selection accent. The large proofing field supplies the only deliberate stage, while metadata and canvas operations stay close at hand without becoming dashboard chrome.

**Key Characteristics:**

- Native macOS split-view hierarchy rather than a browser-shaped shell.
- A component-first proofing canvas with stable framing and generous working space.
- System semantic colors and controls that adapt automatically to appearance and accessibility settings.
- Dense, aligned navigation and metadata with minimal decoration.
- One elevated live specimen; surrounding surfaces remain flat.

## Colors

The palette is the current macOS appearance: cool system neutrals, primary and secondary label semantics, and the user's system selection color. Fixed white and black exist only as explicit proofing backgrounds.

### Primary

- **System Selection Accent** (`SelectedItem`, native list selection): Marks the current component or story. The operating system owns its hue and selected-label contrast.

### Neutral

- **Window Ground** (`NSColor.windowBackgroundColor`): Frames the detail workspace and empty canvas states.
- **Control Ground** (`NSColor.controlBackgroundColor`): Carries the inspector and other control-oriented surfaces.
- **Text Ground** (`NSColor.textBackgroundColor`): Provides the neutral thumbnail well behind rendered preview images.
- **Primary Label** (SwiftUI primary foreground): Carries story names, section headings, and active metadata.
- **Secondary Label** (SwiftUI secondary foreground): Carries counts, layout summaries, provenance, icons, and non-blocking status.
- **Hairline Separator** (`NSColor.separatorColor`): Divides inspector sections, outlines thumbnails, and draws the optional grid at reduced opacity.
- **Proofing Canvas** (`NSColor.galleryCanvasBackground`): Uses a neutral device-white value of 0.91 in Aqua and 0.13 in Dark Aqua so specimens read clearly without competing with them.
- **Proof White / Proof Black** (`Color.white` / `Color.black`): Explicit canvas choices for testing contrast, never application chrome.

**The System Owns Color Rule.** Use dynamic macOS semantic colors for interface chrome and selection. Do not freeze those roles into brand hex values.

**The Canvas Exception Rule.** Fixed white and black are allowed only when the user deliberately selects them as specimen-testing conditions.

## Typography

**Display Font:** None; this is an operating workspace, not a presentation surface.
**Body Font:** San Francisco through SwiftUI system text styles.
**Label/Mono Font:** San Francisco; tabular numeric readouts use the system monospaced-digit treatment.

**Character:** Compact, familiar, and information-led. Hierarchy comes from native semantic styles and modest weight changes, not oversized type or decorative faces.

### Hierarchy

- **Title** (system `title3`, semibold): The selected story heading in the inspector.
- **Headline** (system `headline`): Inspector section titles.
- **Body** (system `body`, medium): Story names in the contact sheet.
- **Label** (system `subheadline` and `caption`): Provenance, layout summaries, metadata values, counts, and loading or error messages.
- **Numeric** (system `callout`, monospaced digits): Zoom percentage and other changing numeric readouts that must not shift horizontally.

**The Semantic Type Rule.** Preserve SwiftUI text styles so the gallery follows macOS typography and accessibility behavior; do not substitute fixed point sizes.

## Layout

The window is a balanced `NavigationSplitView` with a compact module/component sidebar, a narrow story contact sheet, and a dominant detail canvas. The sidebar ranges from 190 to 300 points with a 230-point ideal; the story list ranges from 230 to 360 points with a 280-point ideal. The optional trailing inspector ranges from 240 to 360 points with a 280-point ideal. The complete gallery has a minimum working size of 900 × 560 points.

The live specimen is centered inside a two-axis scrolling field with an 80-point inset. Story thumbnails are fixed at 92 × 62 points so rows remain scanable while their preview contents scale to fit. Inspector sections use 16-point insets and compact vertical rhythms; list rows rely on native list spacing plus a 5-point vertical inset.

Canvas state remains stable while a newly selected story replaces the specimen. Zoom ranges from 30% to 200% in 10% steps, and both the canvas and selection are kept centered after resets or story changes.

**The Component Owns the Room Rule.** Preserve the canvas as the widest region; navigation and metadata columns may clarify the specimen but must not visually outrank it.

## Elevation & Depth

The interface is flat and structurally divided by split-view boundaries, list selection, tonal surface changes, and half-point hairlines. The live preview alone floats above the proofing field with a soft black shadow at 12% opacity, an 18-point blur radius, and a 7-point vertical offset. This isolates arbitrary preview edges without turning navigation into a card stack.

**The One Lift Rule.** Elevate the live specimen only. Sidebar rows, story rows, inspector sections, and tool controls remain native and flat.

## Shapes

The form language is predominantly square and system-native. SwiftUI owns control silhouettes, list selection shapes, menus, and toolbar grouping. The sole explicit recurring radius is the story thumbnail's gently curved 6-point continuous corner, paired with a half-point separator outline. Proofing backgrounds, inspector sections, and split-view columns do not introduce decorative rounding.

**The Native Geometry Rule.** Let macOS controls supply their own corner behavior; add a custom radius only when content clipping requires it.

## Components

### Navigation

- **Sidebar:** A native sidebar list grouped by module, with a secondary stack icon and monospaced preview count. Search lives in the sidebar and filters modules, components, and story names.
- **Selection:** Uses the system list selection treatment and exposes one current component at a time.
- **Empty state:** Uses `ContentUnavailableView` for empty searches and undiscovered previews rather than a custom card.

### Story Contact Sheet

- **Row:** A compact horizontal row with 12 points between the thumbnail and copy, plus a 5-point vertical inset.
- **Thumbnail:** A 92 × 62 point text-background well, clipped to a 6-point continuous radius and outlined by a half-point semantic separator.
- **Copy:** Medium-weight body text names the state; a secondary caption reports its layout mode.
- **Loading / error:** A small native progress indicator or secondary warning symbol occupies the same thumbnail frame.

### Proofing Canvas

- **Stage:** A scrollable neutral field that can switch among adaptive canvas, white, black, and checkerboard backgrounds.
- **Specimen:** A live, interactive preview centered with an 80-point working inset and the system's only custom shadow.
- **Grid:** An optional 20-point grid drawn with half-point separator lines at 40% opacity; it is visual guidance, not interactive content.
- **Checkerboard:** A 12-point pattern using white and the semantic quaternary label color, hidden from accessibility.

### Toolbar Controls

- **Style:** Native toolbar buttons, menus, pickers, and a control group; there are no custom button fills or branded treatments.
- **Operations:** Zoom, canvas background, preview appearance, grid visibility, reset, and inspector visibility only.
- **Feedback:** Labels, help text, accessibility values, disabled bounds, and SF Symbols make state legible without extra decoration.

### Inspector

- **Surface:** A semantic control background in a trailing native inspector that never overlays the specimen.
- **Header:** A semibold `title3` story name and secondary `subheadline` component provenance, both selectable.
- **Sections:** Headline labels, 16-point padding, and top dividers organize source, layout, rendering, tags, and context.
- **Values:** Caption-sized `LabeledContent` aligns keys and trailing secondary values; long values remain selectable.

## Do's and Don'ts

### Do:

- **Do** use native split views, lists, inspectors, toolbars, menus, search, empty states, and accessibility semantics.
- **Do** keep the selected component state live, centered, and visually dominant.
- **Do** use semantic system colors and SwiftUI text styles so light, dark, high-contrast, and user-accent settings remain coherent.
- **Do** use hairlines, alignment, and restrained tonal shifts to organize dense engineering information.
- **Do** reserve fixed white, black, checkerboard, and grid treatments for explicit proofing tasks.

### Don't:

- **Don't** turn the catalog into a dashboard of decorative cards.
- **Don't** imitate browser Storybook chrome or introduce web-navigation conventions.
- **Don't** add branded color fills, gradients, ornamental imagery, or display typography to the application chrome.
- **Don't** elevate navigation or metadata surfaces; the live preview is the single lifted object.
- **Don't** expose implementation metadata at the expense of the specimen's working area.
