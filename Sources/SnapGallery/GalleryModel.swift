import AppKit
import Observation
import SnapCore
import SnapModels
import SwiftUI

enum GalleryCanvasBackground: String, CaseIterable, Identifiable {
    case canvas
    case white
    case black
    case checkerboard

    var id: Self { self }

    var label: String {
        switch self {
        case .canvas: "Canvas"
        case .white: "White"
        case .black: "Black"
        case .checkerboard: "Transparency"
        }
    }

    var systemImage: String {
        switch self {
        case .canvas: "rectangle"
        case .white: "sun.max"
        case .black: "moon"
        case .checkerboard: "checkerboard.rectangle"
        }
    }
}

enum GalleryAppearance: String, CaseIterable, Identifiable {
    case automatic
    case light
    case dark

    var id: Self { self }

    var label: String {
        switch self {
        case .automatic: "Preview"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .automatic: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .automatic: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

struct GalleryRenderResult {
    let colorScheme: ColorScheme?
    let preferences: SnapshotPreferenceSnapshot
    let errorDescription: String?
}

@MainActor
@Observable
final class GalleryModel {
    let catalog: GalleryCatalog

    var selectedComponentID: String?
    var selectedStoryID: String?
    var searchText = ""
    var zoom = 1.0
    var canvasBackground = GalleryCanvasBackground.canvas
    var appearance = GalleryAppearance.automatic
    var showsGrid = false
    var showsInspector = true
    var previewGeneration = 0
    private(set) var renderResults: [String: GalleryRenderResult] = [:]

    private let renderer = AppKitPreviewRenderer()
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private var pendingStories: [GalleryStory] = []
    private var pendingStoryIDs: Set<String> = []
    private var isRendering = false

    init(catalog: GalleryCatalog) {
        self.catalog = catalog
        thumbnailCache.totalCostLimit = 128 * 1_024 * 1_024
        let firstComponent = catalog.firstComponent
        selectedComponentID = firstComponent?.id
        selectedStoryID = firstComponent?.stories.first?.id
    }

    var selectedComponent: GalleryComponent? {
        catalog.component(id: selectedComponentID)
    }

    var selectedStory: GalleryStory? {
        catalog.story(id: selectedStoryID)
    }

    var filteredModules: [GalleryModule] {
        catalog.modules.compactMap { module in
            let components = module.components.filter { $0.matches(searchText) }
            guard !components.isEmpty else { return nil }
            return GalleryModule(id: module.id, name: module.name, components: components)
        }
    }

    func selectComponent(_ id: String?) {
        selectedComponentID = id
        guard let component = catalog.component(id: id) else {
            selectedStoryID = nil
            return
        }
        if !component.stories.contains(where: { $0.id == selectedStoryID }) {
            selectedStoryID = component.stories.first?.id
        }
    }

    func selectStory(_ id: String?) {
        selectedStoryID = id
        guard let story = catalog.story(id: id) else { return }
        if selectedComponent?.stories.contains(where: { $0.id == story.id }) != true {
            selectedComponentID = catalog.modules
                .lazy
                .flatMap(\.components)
                .first { component in
                    component.stories.contains { $0.id == story.id }
                }?
                .id
        }
    }

    func renderIfNeeded(_ story: GalleryStory) {
        let cacheKey = story.id as NSString
        guard thumbnailCache.object(forKey: cacheKey) == nil
                || renderResults[story.id] == nil
        else {
            return
        }
        guard pendingStoryIDs.insert(story.id).inserted else { return }
        pendingStories.append(story)
        if !isRendering {
            Task { @MainActor in
                await processRenderQueue()
            }
        }
    }

    func thumbnail(for storyID: String) -> NSImage? {
        thumbnailCache.object(forKey: storyID as NSString)
    }

    private func processRenderQueue() async {
        guard !isRendering else { return }
        isRendering = true

        while !pendingStories.isEmpty {
            let story = pendingStories.removeFirst()
            pendingStoryIDs.remove(story.id)

            let outcome = await renderer.renderForGallery(story.preview)
            if let image = outcome.image {
                thumbnailCache.setObject(
                    image,
                    forKey: story.id as NSString,
                    cost: image.tiffRepresentation?.count ?? 0
                )
            }
            renderResults[story.id] = GalleryRenderResult(
                colorScheme: outcome.colorScheme,
                preferences: outcome.preferences,
                errorDescription: outcome.captureError.map(String.init(describing:))
            )
        }

        isRendering = false
    }

    func resetPreview() {
        previewGeneration += 1
    }

    func resetCanvas() {
        zoom = 1
        canvasBackground = .canvas
        appearance = .automatic
        showsGrid = false
        resetPreview()
    }

    func zoomIn() {
        zoom = min(zoom + 0.1, 2)
    }

    func zoomOut() {
        zoom = max(zoom - 0.1, 0.3)
    }
}
