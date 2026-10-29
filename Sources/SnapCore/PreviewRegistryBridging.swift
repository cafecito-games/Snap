import SwiftUI
import DeveloperToolsSupport

/// Bridges the compiler-synthesized `PreviewRegistry` conformances that the
/// `#Preview` macro emits into preview containers.
///
/// `DeveloperToolsSupport.Preview` hides its stored members from Swift, and
/// the source types backing them (`ViewPreviewSource`,
/// `DefaultPreviewSource`) are no longer visible to source compilation at
/// all. Everything here therefore works through runtime reflection:
///
/// 1. `makePreview()` returns an opaque `Preview` value.
/// 2. The mirror walk reaches the stored view-body closure:
///    `dataSource` → `.preview` → `structure` → `.singlePreview(makeBody:)`.
/// 3. The closure is invoked through a layout-matched placeholder type (see
///    `ViewBodyPlaceholder`).
@MainActor
enum PreviewRegistryBridging {
    enum BridgingError: Error, CustomStringConvertible {
        case makePreviewFailed(String, underlying: Error)
        case unrecognizedSourceShape(String)
        case missingPreviewBody(String)

        var description: String {
            switch self {
            case .makePreviewFailed(let typeName, let underlying):
                return "makePreview() threw for \(typeName): \(underlying)"
            case .unrecognizedSourceShape(let typeName):
                return """
                    Preview \(typeName) uses a data source shape this version of Snap \
                    does not recognize. Please update Snap.
                    """
            case .missingPreviewBody(let typeName):
                return "Preview \(typeName) did not expose a view body closure."
            }
        }
    }

    static func makeContainer(
        typeName: String,
        registry: any PreviewRegistry.Type
    ) throws -> PreviewContainer {
        let preview: DeveloperToolsSupport.Preview
        do {
            preview = try registry.makePreview()
        } catch {
            throw BridgingError.makePreviewFailed(typeName, underlying: error)
        }

        let mirror = Mirror(reflecting: preview)
        let displayName = mirror.descendant("displayName") as? String
        let layout = preferredLayout(mirror: mirror)
        let makeView = try makeViewClosure(mirror: mirror, typeName: typeName)

        let previewItem = RenderablePreview(
            containerTypeName: typeName,
            fileID: registry.fileID,
            line: registry.line,
            displayName: displayName,
            index: 0,
            layout: layout,
            makeView: makeView
        )
        return PreviewContainer(
            typeName: typeName,
            fileID: registry.fileID,
            line: registry.line,
            previews: [previewItem]
        )
    }

    /// Reads the declared layout trait, if any, out of the preview's traits.
    private static func preferredLayout(mirror: Mirror) -> PreviewLayout {
        guard let traits = mirror.descendant("traits") else {
            return .device
        }
        for trait in Mirror(reflecting: traits).children {
            guard let value = Mirror(reflecting: trait.value).descendant("value") else {
                continue
            }
            if let layout = value as? PreviewLayout {
                return layout
            }
        }
        return .device
    }

    /// Extracts the `@MainActor () -> any View` closure out of the preview's
    /// data source, across every source shape Snap knows about.
    private static func makeViewClosure(
        mirror: Mirror,
        typeName: String
    ) throws -> (@MainActor () -> any View) {
        guard let source = mirror.descendant("dataSource", "preview") else {
            throw BridgingError.unrecognizedSourceShape(typeName)
        }
        let sourceMirror = Mirror(reflecting: source)

        // Xcode 16 shape: `ViewPreviewSource` stores `makeView` directly.
        if let makeViewChild = sourceMirror.children.first(where: { $0.label == "makeView" }) {
            if let closure = functionCast(makeViewChild.value) {
                return closure
            }
        }

        // Xcode 26 shape: `DefaultPreviewSource<ViewPreviewBody>` wraps the
        // body closure in `structure` → `.singlePreview(makeBody:)`.
        if
            let structureChild = sourceMirror.children.first(where: { $0.label == "structure" }),
            let body = viewBody(fromStructure: structureChild.value)
        {
            return body
        }

        throw BridgingError.unrecognizedSourceShape(typeName)
    }

    /// Navigates `structure` values for the `singlePreview` payload and
    /// invokes its `makeBody` closure.
    private static func viewBody(fromStructure structure: Any) -> (@MainActor () -> any View)? {
        for child in Mirror(reflecting: structure).children {
            // Depending on how the payload is reflected, the closure is
            // either a direct child or inside the case payload tuple.
            let candidates = [child] + Mirror(reflecting: child.value).children
            for candidate in candidates {
                if let closureChild = labeledClosureChild(candidate) {
                    return invokeViewBodyClosure(closureChild.value)
                }
            }
        }
        return nil
    }

    private static func labeledClosureChild(_ child: Mirror.Child) -> Mirror.Child? {
        let isClosureLabel = child.label == "makeBody" || child.label == "makeView"
        guard isClosureLabel else { return nil }
        return child
    }

    private static func invokeViewBodyClosure(_ closureValue: Any) -> (@MainActor () -> any View)? {
        func open<Value>(_ closure: Value) -> (@MainActor () -> any View)? {
            guard String(describing: Value.self).contains("() ->") else {
                return nil
            }
            let makeBody = unsafeBitCast(
                closure,
                to: (@MainActor () -> ViewBodyPlaceholder).self
            )
            return { makeBody().body }
        }
        return _openExistential(closureValue, do: open)
    }

    /// Casts an erased closure to `@MainActor () -> any View` when its
    /// concrete type matches exactly.
    private static func functionCast(_ value: Any) -> (@MainActor () -> any View)? {
        value as? (@MainActor () -> any View)
    }
}

/// Layout-matched stand-in for SwiftUI's private `ViewPreviewBody` type,
/// which stores a single erased `any View`.
///
/// The bit-cast in `invokeViewBodyClosure` is only sound while
/// `ViewPreviewBody` remains a single-property wrapper around an
/// `any View` existential, which is verified by the extraction spikes this
/// implementation was built against.
private struct ViewBodyPlaceholder {
    var body: any View
}
