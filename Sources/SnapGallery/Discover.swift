import SnapCore

/// A rule that discovers compiled SwiftUI previews for a gallery.
///
/// The module name is an exact Swift module name. Preview filters are regular
/// expressions matched against Snap's preview names.
public struct Discover: Sendable {
    let includedPreviews: [String]?
    let excludedPreviews: [String]?
    let includedModules: [String]?
    let excludedModules: [String]?

    /// Discovers previews from one module.
    ///
    /// Pass preview-name patterns to narrow the stories contributed by this
    /// rule. Empty pattern arrays leave that dimension unrestricted.
    public init(
        _ module: String,
        including includedPreviews: [String] = [],
        excluding excludedPreviews: [String] = []
    ) {
        includedModules = [module]
        excludedModules = nil
        self.includedPreviews = includedPreviews.nilIfEmpty
        self.excludedPreviews = excludedPreviews.nilIfEmpty
    }

    /// Discovers previews from the module that declares `marker`.
    ///
    /// Use an existing public type or a dedicated empty marker type. Because
    /// the compiler resolves the type reference, this form follows module and
    /// type renames and also keeps the declaring module linked into the host.
    public init<Marker>(
        from marker: Marker.Type,
        including includedPreviews: [String] = [],
        excluding excludedPreviews: [String] = []
    ) {
        includedModules = [Self.moduleName(of: marker)]
        excludedModules = nil
        self.includedPreviews = includedPreviews.nilIfEmpty
        self.excludedPreviews = excludedPreviews.nilIfEmpty
    }

    /// Discovers previews from every module linked into the gallery process.
    public init(
        including includedPreviews: [String] = [],
        excluding excludedPreviews: [String] = []
    ) {
        includedModules = nil
        excludedModules = nil
        self.includedPreviews = includedPreviews.nilIfEmpty
        self.excludedPreviews = excludedPreviews.nilIfEmpty
    }

    init(
        includedPreviews: [String]?,
        excludedPreviews: [String]?,
        includedModules: [String]?,
        excludedModules: [String]?
    ) {
        self.includedPreviews = includedPreviews
        self.excludedPreviews = excludedPreviews
        self.includedModules = includedModules
        self.excludedModules = excludedModules
    }

    var selection: PreviewSelection {
        PreviewSelection(
            includedPreviewNames: includedPreviews,
            excludedPreviewNames: excludedPreviews,
            includedModules: includedModules,
            excludedModules: excludedModules
        )
    }

    private static func moduleName(of marker: Any.Type) -> String {
        let qualifiedName = String(reflecting: marker)
        return String(qualifiedName.split(separator: ".", maxSplits: 1).first ?? "")
    }
}

/// Builds the discovery rules that supply a ``SnapGallery``.
@resultBuilder
public enum SnapGalleryBuilder {
    public static func buildExpression(_ expression: Discover) -> [Discover] {
        [expression]
    }

    public static func buildBlock(_ components: [Discover]...) -> [Discover] {
        components.flatMap { $0 }
    }

    public static func buildOptional(_ component: [Discover]?) -> [Discover] {
        component ?? []
    }

    public static func buildEither(first component: [Discover]) -> [Discover] {
        component
    }

    public static func buildEither(second component: [Discover]) -> [Discover] {
        component
    }

    public static func buildArray(_ components: [[Discover]]) -> [Discover] {
        components.flatMap { $0 }
    }
}

private extension Array {
    var nilIfEmpty: Self? {
        isEmpty ? nil : self
    }
}
