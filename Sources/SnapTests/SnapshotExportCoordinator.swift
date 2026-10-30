import Foundation
import XCTest
import SnapModels
import SnapCore

/// Writes rendered snapshots as PNG files plus JSON metadata sidecars when
/// `SNAPSHOTS_EXPORT_DIR` is set, for upload to visual-diff tooling.
///
/// File encoding happens on a background queue so test runs are not
/// serialized behind PNG compression; `testBundleDidFinish` drains any
/// outstanding writes before the process exits.
final class SnapshotExportCoordinator: NSObject, XCTestObservation {

    static let environmentKey = "SNAPSHOTS_EXPORT_DIR"

    static func createFromEnvironment(
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> SnapshotExportCoordinator? {
        guard let exportDirectory = environment[environmentKey] else {
            return nil
        }
        let trimmed = exportDirectory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            preconditionFailure(
                "\(environmentKey) is set but empty. Provide a valid directory path."
            )
        }

        let url: URL
        if trimmed.hasPrefix("/") {
            url = URL(fileURLWithPath: trimmed, isDirectory: true).standardizedFileURL
        } else {
            url = URL(
                fileURLWithPath: FileManager.default.currentDirectoryPath,
                isDirectory: true
            )
            .appendingPathComponent(trimmed, isDirectory: true)
            .standardizedFileURL
        }

        let coordinator = Self(exportDirectoryURL: url)
        XCTestObservationCenter.shared.addTestObserver(coordinator)
        return coordinator
    }

    // MARK: - Sidecar model

    struct Sidecar: Encodable {
        let displayName: String
        let group: String
        let diffThreshold: Float?
        let tags: [String: String]?
        let context: [String: SnapshotMetadataValue]

        init(_ metadata: ExportMetadata) {
            displayName = metadata.preferredDisplayName
            group = metadata.group
            diffThreshold = metadata.diffThreshold
            tags = metadata.tags.isEmpty ? nil : metadata.tags

            var previewContext: [String: SnapshotMetadataValue] = [
                ContextKey.Preview.index: .number(Double(metadata.previewIndex)),
                ContextKey.Preview.containerTypeName: .string(metadata.containerTypeName),
                ContextKey.Preview.containerDisplayName: .string(metadata.containerDisplayName),
                ContextKey.Preview.orientation: .string(metadata.orientation),
            ]
            if let previewDisplayName = metadata.previewDisplayName,
               !previewDisplayName.isEmpty
            {
                previewContext[ContextKey.Preview.displayName] = .string(previewDisplayName)
            }
            if let colorScheme = metadata.colorScheme {
                previewContext[ContextKey.Preview.preferredColorScheme] = .string(colorScheme)
            }
            if let line = metadata.line {
                previewContext[ContextKey.Preview.line] = .number(Double(line))
            }

            var generatedContext: [String: SnapshotMetadataValue] = [
                ContextKey.testName: .string(metadata.testName),
                ContextKey.preview: .object(previewContext),
            ]
            generatedContext.merge(metadata.additionalContext) { _, custom in custom }
            context = generatedContext
        }

        private enum ContextKey {
            static let testName = "test_name"
            static let preview = "preview"

            enum Preview {
                static let index = "index"
                static let containerTypeName = "container_type_name"
                static let containerDisplayName = "container_display_name"
                static let displayName = "display_name"
                static let preferredColorScheme = "preferred_color_scheme"
                static let orientation = "orientation"
                static let line = "line"
            }
        }
    }

    /// Everything needed to describe one exported snapshot.
    struct ExportMetadata {
        let imageFileName: String
        let testName: String
        let containerTypeName: String
        let containerDisplayName: String
        let previewDisplayName: String?
        let previewIndex: Int
        let preferredDisplayName: String
        let group: String
        let line: Int?
        let orientation: String
        let colorScheme: String?
        let diffThreshold: Float?
        let tags: [String: String]
        let additionalContext: [String: SnapshotMetadataValue]
    }

    // MARK: - State

    private let exportDirectoryURL: URL
    private let writeQueue: OperationQueue
    private let stateLock = NSLock()
    private var hasDrained = false

    init(exportDirectoryURL: URL) {
        self.exportDirectoryURL = exportDirectoryURL
        writeQueue = OperationQueue()
        writeQueue.maxConcurrentOperationCount = 20
        writeQueue.qualityOfService = .userInitiated
        super.init()

        do {
            try FileManager.default.createDirectory(
                at: exportDirectoryURL,
                withIntermediateDirectories: true
            )
        } catch {
            preconditionFailure(
                "Snap: could not create snapshot export directory at \(exportDirectoryURL.path): \(error)"
            )
        }
    }

    func enqueue(bitmap: SnapshotBitmap, metadata: ExportMetadata) {
        let pngURL = exportDirectoryURL.appendingPathComponent(metadata.imageFileName)
        let sidecarURL = exportDirectoryURL.appendingPathComponent(
            String(metadata.imageFileName.dropLast(".png".count)) + ".json"
        )
        let sidecar = Sidecar(metadata)

        writeQueue.addOperation {
            guard let pngData = bitmap.pngData() else {
                NSLog("[Snap] Failed to encode PNG for %@", metadata.imageFileName)
                return
            }
            do {
                try pngData.write(to: pngURL, options: .atomic)
            } catch {
                NSLog("[Snap] Failed to write PNG %@: %@", metadata.imageFileName, "\(error)")
                return
            }

            do {
                let encoder = JSONEncoder()
                encoder.keyEncodingStrategy = .convertToSnakeCase
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(sidecar)
                try data.write(to: sidecarURL, options: .atomic)
            } catch {
                NSLog("[Snap] Failed to write sidecar %@: %@", sidecarURL.lastPathComponent, "\(error)")
            }
        }
    }

    func drain() {
        stateLock.lock()
        let alreadyDrained = hasDrained
        hasDrained = true
        stateLock.unlock()
        guard !alreadyDrained else {
            return
        }
        writeQueue.waitUntilAllOperationsAreFinished()
    }

    func testBundleDidFinish(_ testBundle: Bundle) {
        drain()
    }
}

