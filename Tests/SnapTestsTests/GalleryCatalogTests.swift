import SwiftUI
import XCTest
@testable import SnapCore
@testable import SnapGallery
@testable import SnapModels
@testable import SnapPreferences

@MainActor
final class GalleryCatalogTests: XCTestCase {
    func testGroupsMacroPreviewsFromTheSameFileIntoOneComponent() {
        let containers = [
            makeContainer(
                typeName: "Feature.FirstRegistry",
                fileID: "Feature/Buttons.swift",
                line: 10,
                displayName: "Primary"
            ),
            makeContainer(
                typeName: "Feature.SecondRegistry",
                fileID: "Feature/Buttons.swift",
                line: 20,
                displayName: "Disabled"
            ),
        ]

        let catalog = GalleryCatalog(containers: containers)

        XCTAssertEqual(catalog.modules.map(\.name), ["Feature"])
        XCTAssertEqual(catalog.modules[0].components.count, 1)
        XCTAssertEqual(catalog.modules[0].components[0].name, "Buttons")
        XCTAssertEqual(
            catalog.modules[0].components[0].stories.map(\.name),
            ["Primary", "Disabled"]
        )
    }

    func testKeepsPreviewProviderChildrenInOneComponent() {
        let previews = [
            makePreview(
                containerTypeName: "Feature.ButtonPreviews",
                displayName: "Regular",
                index: 0
            ),
            makePreview(
                containerTypeName: "Feature.ButtonPreviews",
                displayName: "Pressed",
                index: 1
            ),
        ]
        let container = PreviewContainer(
            typeName: "Feature.ButtonPreviews",
            fileID: nil,
            line: nil,
            previews: previews
        )

        let component = GalleryCatalog(containers: [container]).firstComponent

        XCTAssertEqual(component?.name, "Button")
        XCTAssertEqual(component?.stories.map(\.name), ["Regular", "Pressed"])
    }

    func testSearchMatchesAStoryName() {
        let container = makeContainer(
            typeName: "Feature.SyncRegistry",
            fileID: "Feature/Sync.swift",
            line: 30,
            displayName: "Failure Banner"
        )
        let component = GalleryCatalog(containers: [container]).firstComponent

        XCTAssertTrue(component?.matches("failure") == true)
        XCTAssertFalse(component?.matches("unrelated") == true)
    }

    func testStoryIdentityIsStableForMacroPreviews() {
        let container = makeContainer(
            typeName: "Feature.SyncRegistry",
            fileID: "Feature/Sync.swift",
            line: 30,
            displayName: "Failure Banner"
        )

        let firstID = GalleryCatalog(containers: [container]).firstComponent?.stories.first?.id
        let secondID = GalleryCatalog(containers: [container]).firstComponent?.stories.first?.id

        XCTAssertEqual(firstID, "Feature/Sync.swift:30:0")
        XCTAssertEqual(firstID, secondID)
    }

    func testGalleryRendererReadsPreferencesAfterAsyncCommit() async throws {
        installPreferenceBridge()
        let moduleName = String(
            String(reflecting: Self.self).split(separator: ".").first ?? ""
        )
        let preview = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(includedModules: [moduleName])
        )
        .flatMap(\.previews)
        .first { $0.displayName == "Fixture With Preferences" }

        let outcome = await AppKitPreviewRenderer().renderForGallery(
            try XCTUnwrap(preview)
        )

        XCTAssertEqual(outcome.preferences.tags, ["area": "fixtures"])
        XCTAssertEqual(outcome.preferences.diffThreshold, 0.1)
        XCTAssertEqual(
            outcome.preferences.additionalContext,
            ["fixture": .string("tagged")]
        )
    }

    func testScaledPreviewLayoutExpandsScrollableBounds() {
        let contentSize = CGSize(width: 320, height: 180)

        XCTAssertEqual(
            GalleryScaledPreviewLayout.frameSize(contentSize: contentSize, zoom: 0.3),
            CGSize(width: 96, height: 54)
        )
        XCTAssertEqual(
            GalleryScaledPreviewLayout.frameSize(contentSize: contentSize, zoom: 1),
            contentSize
        )
        XCTAssertEqual(
            GalleryScaledPreviewLayout.frameSize(contentSize: contentSize, zoom: 2),
            CGSize(width: 640, height: 360)
        )
    }

    func testLivePreviewSizingMatchesRendererProposals() {
        XCTAssertEqual(
            GalleryPreviewSizing.proposedSize(for: .fixed(width: 360, height: 240)),
            CGSize(width: 360, height: 240)
        )
        XCTAssertEqual(
            GalleryPreviewSizing.proposedSize(for: .device),
            CGSize(width: 800, height: 400)
        )
        XCTAssertEqual(
            GalleryPreviewSizing.proposedSize(for: .sizeThatFits),
            CGSize(width: 800, height: 400)
        )
    }

    func testResetRestoresCanvasAndCreatesFreshPreviewIdentity() {
        let catalog = GalleryCatalog(
            containers: [
                makeContainer(
                    typeName: "Feature.CounterRegistry",
                    fileID: "Feature/Counter.swift",
                    line: 10,
                    displayName: "Interactive Counter"
                ),
            ]
        )
        let model = GalleryModel(catalog: catalog)
        let storyID = try? XCTUnwrap(model.selectedStoryID)
        let originalIdentity = storyID.map {
            GalleryLivePreviewIdentity.value(
                storyID: $0,
                appearance: model.appearance,
                generation: model.previewGeneration
            )
        }

        model.zoom = 1.8
        model.canvasBackground = .black
        model.appearance = .dark
        model.showsGrid = true
        model.resetCanvas()

        XCTAssertEqual(model.zoom, 1)
        XCTAssertEqual(model.canvasBackground, .canvas)
        XCTAssertEqual(model.appearance, .automatic)
        XCTAssertFalse(model.showsGrid)
        XCTAssertEqual(model.previewGeneration, 1)
        XCTAssertNotEqual(
            originalIdentity,
            storyID.map {
                GalleryLivePreviewIdentity.value(
                    storyID: $0,
                    appearance: model.appearance,
                    generation: model.previewGeneration
                )
            }
        )
    }

    func testRenderQueueProcessesMultipleStoriesSerially() async throws {
        installPreferenceBridge()
        let containers = (0..<6).map { index in
            makeContainer(
                typeName: "Feature.Registry\(index)",
                fileID: "Feature/Component\(index).swift",
                line: index + 1,
                displayName: "State \(index)"
            )
        }
        let model = GalleryModel(catalog: GalleryCatalog(containers: containers))
        let stories = model.catalog.modules.flatMap(\.components).flatMap(\.stories)

        stories.forEach(model.renderIfNeeded)
        for _ in 0..<50 where model.renderResults.count < stories.count {
            try await Task.sleep(for: .milliseconds(20))
        }

        XCTAssertEqual(model.renderResults.count, stories.count)
        XCTAssertTrue(stories.allSatisfy { model.thumbnail(for: $0.id) != nil })
    }

    private func installPreferenceBridge() {
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
    }

    private func makeContainer(
        typeName: String,
        fileID: String,
        line: Int,
        displayName: String
    ) -> PreviewContainer {
        PreviewContainer(
            typeName: typeName,
            fileID: fileID,
            line: line,
            previews: [
                RenderablePreview(
                    containerTypeName: typeName,
                    fileID: fileID,
                    line: line,
                    displayName: displayName,
                    index: 0,
                    layout: .sizeThatFits,
                    makeView: { Text(displayName) }
                ),
            ]
        )
    }

    private func makePreview(
        containerTypeName: String,
        displayName: String,
        index: Int
    ) -> RenderablePreview {
        RenderablePreview(
            containerTypeName: containerTypeName,
            fileID: nil,
            line: nil,
            displayName: displayName,
            index: index,
            layout: .sizeThatFits,
            makeView: { Text(displayName) }
        )
    }
}
