import XCTest
import SwiftUI
import SnapCore
import SnapModels

/// A test class that renders every discovered Xcode preview on macOS.
///
/// Subclass `SnapTest` in an XCTest target and run it — there are no test
/// methods to write. One XCTest method is generated per discovered preview:
///
///     import SnapTests
///     import MyFeature
///
///     final class MyFeaturePreviewTests: SnapTest {
///         override class func includedModules() -> [String]? {
///             ["MyFeature"]
///         }
///     }
open class SnapTest: SnapDynamicTestCase {

    @MainActor
    private static var renderer: AppKitPreviewRenderer?
    @MainActor
    private static var fileNameResolver = SnapshotFileNameResolver(containers: [])
    @MainActor
    private static var exportCoordinator: SnapshotExportCoordinator?
    @MainActor
    private static var imageNameWriter: SnapshotImageNameWriter?

    // MARK: - Filters

    /// Restricts rendering to previews whose filter name matches any of the
    /// given regular-expression patterns. `nil` renders everything.
    ///
    /// `#Preview` macros filter as `"Module/File.swift:Display Name"`;
    /// `PreviewProvider` types filter by their fully-qualified type name.
    open class func includedPreviews() -> [String]? {
        nil
    }

    /// Excludes previews whose filter name matches any of the given
    /// regular-expression patterns.
    open class func excludedPreviews() -> [String]? {
        nil
    }

    /// Restricts rendering to previews declared in the given modules.
    open class func includedModules() -> [String]? {
        nil
    }

    /// Excludes previews declared in the given modules.
    open class func excludedModules() -> [String]? {
        nil
    }

    // MARK: - Discovery

    @MainActor
    override open class func discoverPreviewContainers() -> [PreviewContainer] {
        // The two environment-driven modes are mutually exclusive: listing
        // names never renders, and rendering never lists names.
        if let writer = SnapshotImageNameWriter.createFromEnvironment() {
            imageNameWriter = writer
            let containers = discoverContainersApplyingFilters()
            writer.write(containers: containers)
            return []
        }
        exportCoordinator = SnapshotExportCoordinator.createFromEnvironment()
        return discoverContainersApplyingFilters()
    }

    @MainActor
    private static func discoverContainersApplyingFilters() -> [PreviewContainer] {
        let containers = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(
                includedPreviewNames: includedPreviews(),
                excludedPreviewNames: excludedPreviews(),
                includedModules: includedModules(),
                excludedModules: excludedModules()
            )
        )
        fileNameResolver = SnapshotFileNameResolver(containers: containers)
        return containers
    }

    // MARK: - Execution

    /// Whether rendered previews are captured as images. Layout-only
    /// subclasses disable this.
    open class func capturesImages() -> Bool {
        true
    }

    @MainActor
    override open func run(pendingCase: PendingPreviewCase) {
        let preview = pendingCase.preview
        let container = pendingCase.container

        let renderer: AppKitPreviewRenderer
        if let existing = Self.renderer {
            renderer = existing
        } else {
            renderer = AppKitPreviewRenderer()
            Self.renderer = renderer
        }

        let outcome = renderer.render(preview, captureImage: Self.capturesImages())

        if let captureError = outcome.captureError {
            XCTFail("Snap: rendering failed for \(container.typeName): \(captureError)")
            return
        }

        guard
            let baseFileName = Self.fileNameResolver.baseFileName(
                containerTypeName: container.typeName,
                previewIndex: preview.index
            )
        else {
            XCTFail("Snap: no file name resolved for \(container.typeName) index \(preview.index)")
            return
        }
        let imageFileName = SnapshotFileName.imageFileName(from: baseFileName)

        if let coordinator = Self.exportCoordinator {
            guard let image = outcome.image else {
                XCTFail("Snap: no image was captured for \(imageFileName)")
                return
            }
            coordinator.enqueue(
                image: image,
                metadata: SnapshotExportCoordinator.ExportMetadata(
                    imageFileName: imageFileName,
                    testName: name,
                    containerTypeName: container.typeName,
                    containerDisplayName: container.displayName,
                    previewDisplayName: preview.displayName,
                    previewIndex: preview.index,
                    preferredDisplayName: preferredDisplayName(
                        previewDisplayName: preview.displayName,
                        line: container.line,
                        previewIndex: preview.index
                    ),
                    group: container.groupName,
                    line: container.line,
                    orientation: "portrait",
                    colorScheme: outcome.colorScheme.map(\.sidecarValue),
                    diffThreshold: outcome.preferences.diffThreshold,
                    tags: outcome.preferences.tags,
                    additionalContext: outcome.preferences.additionalContext
                )
            )
        } else if let image = outcome.image {
            guard let pngData = image.pngData() else {
                XCTFail("Snap: could not encode PNG for \(imageFileName)")
                return
            }
            let attachment = XCTAttachment(
                data: pngData,
                uniformTypeIdentifier: "public.png"
            )
            attachment.name = String(imageFileName.dropLast(".png".count))
            attachment.lifetime = .keepAlways
            add(attachment)
        } else {
            XCTFail("Snap: no image was captured for \(imageFileName)")
        }
    }

    private func preferredDisplayName(
        previewDisplayName: String?,
        line: Int?,
        previewIndex: Int
    ) -> String {
        if let previewDisplayName, !previewDisplayName.isEmpty {
            return previewDisplayName
        }
        if line != nil {
            return "At line #\(line!)"
        }
        return String(previewIndex)
    }
}

private extension ColorScheme {
    var sidecarValue: String {
        switch self {
        case .light:
            return "light"
        case .dark:
            return "dark"
        @unknown default:
            return "unknown"
        }
    }
}
