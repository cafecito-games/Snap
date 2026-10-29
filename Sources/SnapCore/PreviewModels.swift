import SwiftUI

/// One renderable preview: a single view together with the metadata needed to
/// name, filter, and lay it out.
@MainActor
public final class RenderablePreview {
    /// The fully-qualified name of the declaring type. For `#Preview` macros
    /// this is the compiler-synthesized `PreviewRegistry` struct.
    public let containerTypeName: String

    /// `#fileID` of the declaration, for macro previews. `nil` for
    /// `PreviewProvider` previews.
    public let fileID: String?

    /// Source line of the declaration, for macro previews.
    public let line: Int?

    /// The preview's display name: the `#Preview("name")` argument, or the
    /// `.previewDisplayName(...)` value for provider previews.
    public let displayName: String?

    /// Zero-based position of this preview within its container.
    public let index: Int

    /// The layout the preview requested.
    public let layout: PreviewLayout

    /// Builds a fresh view for rendering. Called once per render so that no
    /// view state leaks between snapshots.
    let makeView: @MainActor () -> any View

    init(
        containerTypeName: String,
        fileID: String?,
        line: Int?,
        displayName: String?,
        index: Int,
        layout: PreviewLayout,
        makeView: @escaping @MainActor () -> any View
    ) {
        self.containerTypeName = containerTypeName
        self.fileID = fileID
        self.line = line
        self.displayName = displayName
        self.index = index
        self.layout = layout
        self.makeView = makeView
    }
}

/// A declaration that holds one or more previews: either a
/// `PreviewProvider`-conforming type or the compiler-synthesized
/// `PreviewRegistry` struct of a `#Preview` macro.
@MainActor
public final class PreviewContainer {
    public let typeName: String
    public let fileID: String?
    public let line: Int?
    public let previews: [RenderablePreview]

    init(typeName: String, fileID: String?, line: Int?, previews: [RenderablePreview]) {
        self.typeName = typeName
        self.fileID = fileID
        self.line = line
        self.previews = previews
    }

    /// The module that declared the container: the first component of the
    /// type name.
    public var moduleName: String {
        String(typeName.split(separator: ".").first ?? "")
    }

    /// The preferred name used when filtering previews by name. For macro
    /// previews this combines the file ID and display name.
    public var filterName: String {
        guard let fileID else {
            return typeName
        }
        guard let displayName = previews.first?.displayName, !displayName.isEmpty else {
            return fileID
        }
        return "\(fileID):\(displayName)"
    }

    /// The grouping key used when naming and organizing exported snapshots:
    /// the file for macro previews, otherwise the display or type name.
    public var groupName: String {
        if let fileID, !fileID.isEmpty {
            return fileID
        }
        let name = displayName
        return name.isEmpty ? typeName : name
    }

    /// A human-readable name for the container, derived from the file name or
    /// type name.
    public var displayName: String {
        if let fileID {
            let fileName = fileID.split(separator: "/").last ?? Substring(fileID)
            let stem = fileName.split(separator: ".").first ?? fileName
            return String(stem).splitByWords().joined(separator: " ")
        }
        let withoutModule = typeName.split(separator: ".").dropFirst().joined(separator: ".")
        let words = withoutModule.splitByWords()
        if words.last == "previews" {
            return words.dropLast().joined(separator: " ")
        }
        return words.joined(separator: " ")
    }
}

extension String {
    /// Splits an identifier such as `"WorkspaceView_Previews"` into its
    /// component words: `["workspace", "view", "previews"]`.
    func splitByWords() -> [String] {
        var words: [String] = []
        var current = ""
        for character in self {
            switch character {
            case "_", "-", " ", "/":
                if !current.isEmpty {
                    words.append(current)
                    current = ""
                }
            case let character where character.isUppercase:
                if !current.isEmpty {
                    words.append(current)
                }
                current = String(character.lowercased())
            default:
                current.append(character)
            }
        }
        if !current.isEmpty {
            words.append(current)
        }
        return words
    }
}

