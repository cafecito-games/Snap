import Foundation
import SnapCore

@MainActor
struct GalleryCatalog {
    let modules: [GalleryModule]

    init(containers: [PreviewContainer]) {
        struct ComponentKey: Hashable {
            let moduleName: String
            let groupName: String
        }

        struct ComponentAccumulator {
            let id: String
            let moduleName: String
            let name: String
            var stories: [GalleryStory]
        }

        var accumulators: [ComponentKey: ComponentAccumulator] = [:]
        for container in containers {
            let groupName = container.fileID ?? container.typeName
            let key = ComponentKey(
                moduleName: container.moduleName,
                groupName: groupName
            )
            var accumulator = accumulators[key] ?? ComponentAccumulator(
                id: "\(container.moduleName):\(groupName)",
                moduleName: container.moduleName,
                name: container.displayName.localizedCapitalized,
                stories: []
            )
            accumulator.stories.append(
                contentsOf: container.previews.map { preview in
                    GalleryStory(container: container, preview: preview)
                }
            )
            accumulators[key] = accumulator
        }

        let components = accumulators.values.map { accumulator in
            GalleryComponent(
                id: accumulator.id,
                moduleName: accumulator.moduleName,
                name: accumulator.name,
                stories: accumulator.stories.sorted(by: GalleryStory.sortOrder)
            )
        }

        modules = Dictionary(grouping: components, by: \.moduleName)
            .map { moduleName, components in
                GalleryModule(
                    id: moduleName,
                    name: moduleName,
                    components: components.sorted(by: GalleryComponent.sortOrder)
                )
            }
            .sorted(by: GalleryModule.sortOrder)
    }

    var firstComponent: GalleryComponent? {
        modules.first?.components.first
    }

    func component(id: String?) -> GalleryComponent? {
        guard let id else { return nil }
        return modules.lazy.flatMap(\.components).first { $0.id == id }
    }

    func story(id: String?) -> GalleryStory? {
        guard let id else { return nil }
        return modules.lazy
            .flatMap(\.components)
            .flatMap(\.stories)
            .first { $0.id == id }
    }
}

struct GalleryModule: Identifiable {
    let id: String
    let name: String
    let components: [GalleryComponent]

    static func sortOrder(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}

struct GalleryComponent: Identifiable {
    let id: String
    let moduleName: String
    let name: String
    let stories: [GalleryStory]

    static func sortOrder(_ lhs: Self, _ rhs: Self) -> Bool {
        lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }

    func matches(_ searchText: String) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }
        return moduleName.localizedCaseInsensitiveContains(query)
            || name.localizedCaseInsensitiveContains(query)
            || stories.contains { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

@MainActor
struct GalleryStory: Identifiable {
    let id: String
    let name: String
    let source: String?
    let line: Int?
    let index: Int
    let preview: RenderablePreview

    init(container: PreviewContainer, preview: RenderablePreview) {
        let sourceLine = preview.line ?? container.line
        if let fileID = preview.fileID ?? container.fileID {
            id = "\(fileID):\(sourceLine ?? 0):\(preview.index)"
            source = fileID
        } else {
            id = "\(container.typeName):\(preview.index)"
            source = nil
        }
        line = sourceLine
        index = preview.index

        if let displayName = preview.displayName, !displayName.isEmpty {
            name = displayName
        } else if let sourceLine {
            name = "At line \(sourceLine)"
        } else {
            name = "Preview \(preview.index + 1)"
        }
        self.preview = preview
    }

    var sourceDescription: String? {
        guard let source else { return nil }
        guard let line else { return source }
        return "\(source):\(line)"
    }

    var layoutDescription: String {
        switch preview.layout {
        case .fixed(let width, let height):
            return "Fixed · \(Int(width)) × \(Int(height))"
        case .sizeThatFits:
            return "Size that fits"
        case .device:
            return "Device"
        default:
            return "Automatic"
        }
    }

    static func sortOrder(_ lhs: Self, _ rhs: Self) -> Bool {
        if lhs.line != rhs.line {
            return (lhs.line ?? .max) < (rhs.line ?? .max)
        }
        if lhs.index != rhs.index {
            return lhs.index < rhs.index
        }
        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
    }
}
