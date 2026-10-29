import Foundation
import SnapCore

/// Writes the logical image names of every discovered preview to a file when
/// `SNAPSHOTS_ALL_IMAGE_NAMES_FILE` is set, then skips rendering entirely.
///
/// This supports selective-testing workflows: a first run lists all snapshot
/// names, a filter chooses the subset to render, and a second run executes
/// only those.
final class SnapshotImageNameWriter {

    static let environmentKey = "SNAPSHOTS_ALL_IMAGE_NAMES_FILE"

    private let outputURL: URL
    private let fileManager: FileManager

    static func createFromEnvironment(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> SnapshotImageNameWriter? {
        guard let outputPath = environment[environmentKey] else {
            return nil
        }
        let trimmed = outputPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            preconditionFailure(
                "\(environmentKey) is set but empty. Provide a valid file path."
            )
        }

        let outputURL: URL
        if trimmed.hasPrefix("/") {
            outputURL = URL(fileURLWithPath: trimmed).standardizedFileURL
        } else {
            outputURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                .appendingPathComponent(trimmed)
                .standardizedFileURL
        }
        return Self(outputURL: outputURL, fileManager: fileManager)
    }

    init(outputURL: URL, fileManager: FileManager = .default) {
        self.outputURL = outputURL
        self.fileManager = fileManager

        do {
            try fileManager.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            preconditionFailure(
                "Snap: could not create directory for \(outputURL.path): \(error)"
            )
        }
    }

    @MainActor
    func write(containers: [PreviewContainer]) {
        let resolver = SnapshotFileNameResolver(containers: containers)
        var imageNames: [String] = []
        for container in containers {
            for preview in container.previews {
                guard
                    let imageName = resolver.imageFileName(
                        containerTypeName: container.typeName,
                        previewIndex: preview.index
                    )
                else {
                    continue
                }
                imageNames.append(imageName)
            }
        }

        let sortedNames = Set(imageNames).sorted()
        let contents = sortedNames.isEmpty ? "" : sortedNames.joined(separator: "\n") + "\n"
        guard let data = contents.data(using: .utf8) else {
            preconditionFailure("Snap: could not encode snapshot image names file.")
        }
        do {
            try data.write(to: outputURL, options: .atomic)
        } catch {
            preconditionFailure("Snap: could not write \(outputURL.path): \(error)")
        }
    }
}
