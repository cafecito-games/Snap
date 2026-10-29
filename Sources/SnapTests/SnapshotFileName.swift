import Foundation
import SnapCore

/// Builds stable, filesystem-safe names for exported snapshot files.
enum SnapshotFileName {

    /// The sanitized base file name for one rendered preview.
    static func baseFileName(
        containerDisplayName: String,
        fileID: String?,
        line: Int?,
        previewDisplayName: String?,
        previewIndex: Int,
        duplicateOrdinal: Int?
    ) -> String {
        let prefix: String
        if let fileID, !fileID.isEmpty {
            prefix = fileID
        } else {
            prefix = containerDisplayName
        }
        let component = componentName(
            line: line,
            hasFileID: fileID != nil,
            previewDisplayName: previewDisplayName,
            previewIndex: previewIndex,
            duplicateOrdinal: duplicateOrdinal
        )
        return "\(prefix)_\(component)"
    }

    private static func componentName(
        line: Int?,
        hasFileID: Bool,
        previewDisplayName: String?,
        previewIndex: Int,
        duplicateOrdinal: Int?
    ) -> String {
        if let previewDisplayName, !previewDisplayName.isEmpty {
            if let duplicateOrdinal {
                return "\(previewDisplayName)_\(duplicateOrdinal)"
            }
            return previewDisplayName
        }
        if hasFileID, let line {
            return "line-\(line)"
        }
        return String(previewIndex)
    }

    /// The final image file name, including the extension.
    static func imageFileName(from baseName: String) -> String {
        "\(sanitize(baseName)).png"
    }

    /// Keeps letters, numbers, dots, dashes, and underscores; collapses every
    /// other character into a single underscore and trims separators from the
    /// ends.
    static func sanitize(_ value: String) -> String {
        var result = ""
        var lastWasSeparator = false
        for character in value {
            if character.isLetter || character.isNumber || character == "." || character == "-" || character == "_" {
                result.append(character)
                lastWasSeparator = false
            } else if !lastWasSeparator {
                result.append("_")
                lastWasSeparator = true
            }
        }
        result = result.trimmingCharacters(in: CharacterSet(charactersIn: "_.-"))
        return result.isEmpty ? "snapshot" : result
    }
}

/// Assigns unambiguous file names across all containers of a test run.
///
/// Display names are only unique within reasonable discipline; when the same
/// display name occurs twice in one group, occurrences are numbered.
@MainActor
struct SnapshotFileNameResolver {
    private var baseNames: [ContainerPreviewKey: String] = [:]

    private struct ContainerPreviewKey: Hashable {
        let containerTypeName: String
        let previewIndex: Int
    }

    init(containers: [PreviewContainer]) {
        var occurrencesByGroup: [String: [String: Int]] = [:]
        for container in containers {
            for preview in container.previews {
                guard let displayName = preview.displayName, !displayName.isEmpty else {
                    continue
                }
                occurrencesByGroup[container.groupName, default: [:]][displayName, default: 0] += 1
            }
        }

        var nextOrdinal: [String: [String: Int]] = [:]
        for container in containers {
            for preview in container.previews {
                let displayNameCounts = occurrencesByGroup[container.groupName] ?? [:]
                var duplicateOrdinal: Int?
                if
                    let displayName = preview.displayName,
                    (displayNameCounts[displayName] ?? 0) > 1
                {
                    let next = nextOrdinal[container.groupName, default: [:]][displayName, default: 1]
                    nextOrdinal[container.groupName, default: [:]][displayName] = next + 1
                    duplicateOrdinal = next
                }

                baseNames[ContainerPreviewKey(
                    containerTypeName: container.typeName,
                    previewIndex: preview.index
                )] = SnapshotFileName.baseFileName(
                    containerDisplayName: container.displayName,
                    fileID: container.fileID,
                    line: container.line,
                    previewDisplayName: preview.displayName,
                    previewIndex: preview.index,
                    duplicateOrdinal: duplicateOrdinal
                )
            }
        }
    }

    func baseFileName(containerTypeName: String, previewIndex: Int) -> String? {
        baseNames[ContainerPreviewKey(
            containerTypeName: containerTypeName,
            previewIndex: previewIndex
        )]
    }

    func imageFileName(containerTypeName: String, previewIndex: Int) -> String? {
        baseFileName(
            containerTypeName: containerTypeName,
            previewIndex: previewIndex
        ).map(SnapshotFileName.imageFileName(from:))
    }
}
