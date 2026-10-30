import SnapCore
import SnapModels
import SnapPreferences
import SwiftUI

/// A native macOS component browser backed by the SwiftUI previews compiled
/// into the current process.
///
/// Present `SnapGallery` from a trusted internal app and link that app to the
/// modules whose previews it should discover. Preview declarations remain the
/// sole source of gallery stories; no additional registration is required.
@MainActor
public struct SnapGallery: View {
    @State private var model: GalleryModel

    /// Creates a gallery from declarative preview-discovery rules.
    ///
    /// Each ``Discover`` contributes previews from a linked Swift module.
    /// Overlapping rules are combined without duplicating stories.
    public init(@SnapGalleryBuilder content: () -> [Discover]) {
        self.init(discoveries: content())
    }

    /// Creates a gallery and optionally filters the previews it discovers.
    ///
    /// Preview name filters are regular expressions. Module filters are exact
    /// Swift module names. A `nil` filter leaves that dimension unrestricted.
    public init(
        includedPreviews: [String]? = nil,
        excludedPreviews: [String]? = nil,
        includedModules: [String]? = nil,
        excludedModules: [String]? = nil
    ) {
        self.init(
            discoveries: [
                Discover(
                    includedPreviews: includedPreviews,
                    excludedPreviews: excludedPreviews,
                    includedModules: includedModules,
                    excludedModules: excludedModules
                ),
            ]
        )
    }

    private init(discoveries: [Discover]) {
        SnapPreferencesRuntime.ensureLoaded()
        SnapshotPreferenceReader.install(
            wrapWithPreferences: { view in
                SnapPreferencesRuntime.wrap(view)
            },
            readSnapshot: {
                SnapshotPreferenceSnapshot(
                    renderingMode: SnapPreferencesRuntime.renderingMode.flatMap(
                        SnapshotRenderingMode.init(rawValue:)
                    ),
                    diffThreshold: SnapPreferencesRuntime.diffThreshold,
                    tags: SnapPreferencesRuntime.tags,
                    additionalContext: SnapPreferencesRuntime.additionalContext
                )
            }
        )
        let containers = Self.discoverContainers(for: discoveries)
        _model = State(
            initialValue: GalleryModel(
                catalog: GalleryCatalog(containers: containers)
            )
        )
    }

    static func discoverContainers(for discoveries: [Discover]) -> [PreviewContainer] {
        var seenTypeNames: Set<String> = []

        return discoveries.flatMap { discovery in
            PreviewDiscovery.discoverContainers(selection: discovery.selection)
        }
        .filter { seenTypeNames.insert($0.typeName).inserted }
    }

    public var body: some View {
        @Bindable var model = model

        NavigationSplitView {
            GallerySidebar(model: model)
                .navigationSplitViewColumnWidth(min: 190, ideal: 230, max: 300)
        } content: {
            GalleryStoryList(model: model)
                .navigationSplitViewColumnWidth(min: 230, ideal: 280, max: 360)
        } detail: {
            GalleryCanvas(model: model)
        }
        .navigationSplitViewStyle(.balanced)
        .inspector(isPresented: $model.showsInspector) {
            GalleryInspector(model: model)
                .inspectorColumnWidth(min: 240, ideal: 280, max: 360)
        }
        .toolbar {
            GalleryToolbar(model: model)
        }
        .frame(minWidth: 900, minHeight: 560)
    }
}
