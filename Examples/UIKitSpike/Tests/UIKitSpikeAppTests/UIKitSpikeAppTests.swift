import SnapCore
import UIKitSpikeFixtures
import XCTest

@MainActor
final class UIKitSpikeAppTests: XCTestCase {
    func testDiscoversCompiledMacroPreviews() throws {
        let previews = discoveredPreviews()
        let allContainers = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection()
        )

        XCTAssertEqual(
            Set(previews.compactMap(\.displayName)),
            [
                "UIKit Layer",
                "UIKit Provider",
                "UIKit Spike Card",
                "UIKit Representable",
            ],
            "All discovered containers: \(allContainers.map(\.typeName))"
        )
    }

    func testRendersSwiftUIAndUIKitContentToPNG() async throws {
        let preview = try XCTUnwrap(
            discoveredPreviews().first { $0.displayName == "UIKit Spike Card" }
        )

        let outcome = UIKitPreviewRenderer().render(
            PreviewRenderRequest(
                preview: preview,
                configuration: PreviewRenderConfiguration(
                    viewport: CGSize(width: 320, height: 200),
                    scale: 1
                )
            )
        )

        XCTAssertNil(outcome.captureError)
        let bitmap = try XCTUnwrap(outcome.bitmap)
        XCTAssertEqual(bitmap.size, CGSize(width: 320, height: 200))
        XCTAssertEqual(bitmap.scale, 1)
        XCTAssertEqual(bitmap.cgImage.width, Int(ceil(bitmap.size.width)))
        XCTAssertEqual(bitmap.cgImage.height, Int(ceil(bitmap.size.height)))
        XCTAssertNotNil(bitmap.pngData())
        XCTAssertEqual(
            outcome.preferences.tags,
            ["platform": "uikit", "kind": "swiftui"]
        )
    }

    func testRendersLayerCaptureMode() throws {
        let preview = try XCTUnwrap(
            discoveredPreviews().first { $0.displayName == "UIKit Layer" }
        )

        let outcome = UIKitPreviewRenderer().render(preview)

        XCTAssertNil(outcome.captureError)
        XCTAssertEqual(outcome.preferences.renderingMode, .layer)
        XCTAssertNotNil(outcome.bitmap?.pngData())
    }

    func testReportsInvalidScaleWithoutCrashing() throws {
        let preview = try XCTUnwrap(discoveredPreviews().first)

        let outcome = UIKitPreviewRenderer().render(
            PreviewRenderRequest(
                preview: preview,
                configuration: PreviewRenderConfiguration(scale: 0)
            )
        )

        XCTAssertNil(outcome.bitmap)
        XCTAssertEqual(outcome.captureError, .invalidScale(0))
    }

    private func discoveredPreviews() -> [RenderablePreview] {
        let moduleName = String(
            String(reflecting: UIKitSpikeMarker.self)
                .split(separator: ".", maxSplits: 1)
                .first ?? ""
        )
        return PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(includedModules: [moduleName])
        )
        .flatMap(\.previews)
    }
}
