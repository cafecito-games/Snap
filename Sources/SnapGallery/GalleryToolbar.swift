import SwiftUI

struct GalleryToolbar: ToolbarContent {
    @Bindable var model: GalleryModel

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            ControlGroup {
                Button(action: model.zoomOut) {
                    Image(systemName: "minus")
                }
                .help("Zoom Out")
                .accessibilityLabel("Zoom Out")
                .accessibilityValue(zoomValue)
                .disabled(model.zoom <= 0.3)

                Text(model.zoom, format: .percent.precision(.fractionLength(0)))
                    .font(.callout.monospacedDigit())
                    .frame(minWidth: 42)
                    .accessibilityLabel("Zoom")

                Button(action: model.zoomIn) {
                    Image(systemName: "plus")
                }
                .help("Zoom In")
                .accessibilityLabel("Zoom In")
                .accessibilityValue(zoomValue)
                .disabled(model.zoom >= 2)
            }

            Menu {
                Picker("Background", selection: $model.canvasBackground) {
                    ForEach(GalleryCanvasBackground.allCases) { background in
                        Label(background.label, systemImage: background.systemImage)
                            .tag(background)
                    }
                }
            } label: {
                Label(
                    model.canvasBackground.label,
                    systemImage: model.canvasBackground.systemImage
                )
            }
            .help("Canvas Background")
            .accessibilityLabel("Canvas Background")
            .accessibilityValue(model.canvasBackground.label)

            Menu {
                Picker("Appearance", selection: $model.appearance) {
                    ForEach(GalleryAppearance.allCases) { appearance in
                        Label(appearance.label, systemImage: appearance.systemImage)
                            .tag(appearance)
                    }
                }
            } label: {
                Label(model.appearance.label, systemImage: model.appearance.systemImage)
            }
            .help("Preview Appearance")
            .accessibilityLabel("Preview Appearance")
            .accessibilityValue(model.appearance.label)

            Button {
                model.showsGrid.toggle()
            } label: {
                Label(
                    model.showsGrid ? "Hide Grid" : "Show Grid",
                    systemImage: model.showsGrid ? "grid.circle.fill" : "grid"
                )
            }
            .help(model.showsGrid ? "Hide Grid" : "Show Grid")
            .accessibilityLabel(model.showsGrid ? "Hide Grid" : "Show Grid")
            .accessibilityValue(model.showsGrid ? "On" : "Off")

            Button(action: model.resetCanvas) {
                Label("Reset Canvas and Preview", systemImage: "arrow.counterclockwise")
            }
            .help("Reset Canvas and Preview")
            .accessibilityLabel("Reset Canvas and Preview")

            Button {
                model.showsInspector.toggle()
            } label: {
                Label(
                    model.showsInspector ? "Hide Inspector" : "Show Inspector",
                    systemImage: "sidebar.trailing"
                )
            }
            .help(model.showsInspector ? "Hide Inspector" : "Show Inspector")
            .accessibilityLabel(
                model.showsInspector ? "Hide Inspector" : "Show Inspector"
            )
            .accessibilityValue(model.showsInspector ? "Shown" : "Hidden")
        }
    }

    private var zoomValue: String {
        model.zoom.formatted(.percent.precision(.fractionLength(0)))
    }
}
