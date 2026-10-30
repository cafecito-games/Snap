import XCTest
@testable import SnapCore

@MainActor
final class PreviewRenderingTests: XCTestCase {
    func testRenderProducesPlatformNeutralBitmapAtRequestedScale() throws {
        let preview = try fixturePreview(named: "Fixture Greeting")
        let request = PreviewRenderRequest(
            preview: preview,
            configuration: PreviewRenderConfiguration(
                viewport: CGSize(width: 300, height: 200),
                scale: 1,
                settling: .immediate
            )
        )

        let outcome = AppKitPreviewRenderer().render(request)
        let bitmap = try XCTUnwrap(outcome.bitmap)

        XCTAssertNil(outcome.captureError)
        XCTAssertEqual(bitmap.size, CGSize(width: 300, height: 200))
        XCTAssertEqual(bitmap.scale, 1)
        XCTAssertEqual(bitmap.cgImage.width, Int(ceil(bitmap.size.width)))
        XCTAssertEqual(bitmap.cgImage.height, Int(ceil(bitmap.size.height)))
        XCTAssertNotNil(bitmap.pngData())
    }

    func testRenderCanPerformLayoutWithoutCapturingBitmap() throws {
        let preview = try fixturePreview(named: "Fixture Greeting")
        let request = PreviewRenderRequest(
            preview: preview,
            configuration: PreviewRenderConfiguration(settling: .immediate),
            capturesBitmap: false
        )

        let outcome = AppKitPreviewRenderer().render(request)

        XCTAssertNil(outcome.bitmap)
        XCTAssertNil(outcome.captureError)
    }

    func testRenderReportsInvalidScaleWithoutCrashing() throws {
        let preview = try fixturePreview(named: "Fixture Greeting")
        let request = PreviewRenderRequest(
            preview: preview,
            configuration: PreviewRenderConfiguration(
                scale: 0,
                settling: .immediate
            )
        )

        let outcome = AppKitPreviewRenderer().render(request)

        XCTAssertNil(outcome.bitmap)
        XCTAssertEqual(outcome.captureError, .invalidScale(0))
    }

    private func fixturePreview(named name: String) throws -> RenderablePreview {
        let moduleName = String(
            String(reflecting: Self.self).split(separator: ".", maxSplits: 1).first ?? ""
        )
        return try XCTUnwrap(
            PreviewDiscovery.discoverContainers(
                selection: PreviewSelection(includedModules: [moduleName])
            )
            .flatMap(\.previews)
            .first { $0.displayName == name }
        )
    }
}
