import SwiftUI
import SnapModels

extension View {
    /// Sets the allowed difference threshold for this preview's snapshot.
    ///
    /// A threshold of `0` requires pixel-perfect matches; `1` accepts any
    /// difference. The value is written to the exported sidecar as
    /// `diff_threshold` for downstream visual-diff tooling.
    ///
    /// - Parameter threshold: The fraction of pixels that may differ, or
    ///   `nil` to fall back to the consumer's default.
    public func snapDiffThreshold(_ threshold: Float?) -> some View {
        preference(key: SnapshotDiffThresholdKey.self, value: threshold)
    }

    /// Selects the pixel-capture backend for this preview.
    ///
    /// Use this when the default `.view` capture misses or mis-renders
    /// content, for example blur materials that only the compositor draws.
    public func snapRenderingMode(_ mode: SnapshotRenderingMode) -> some View {
        preference(key: SnapshotRenderingModeKey.self, value: mode.rawValue)
    }

    /// Attaches searchable key-value tags to the exported snapshot sidecar.
    ///
    /// Repeated modifiers merge their dictionaries; later values win for
    /// duplicate keys.
    public func snapTags(_ tags: [String: String]) -> some View {
        preference(key: SnapshotTagsKey.self, value: tags)
    }

    /// Attaches custom metadata to the exported snapshot sidecar's
    /// `context` object.
    ///
    /// Supported values are strings, booleans, finite numbers, and nested
    /// dictionaries of those types. Repeated modifiers merge their
    /// dictionaries; later values win for duplicate keys, and custom keys
    /// override generated context keys.
    public func snapAdditionalContext(_ context: [String: Any]) -> some View {
        preference(
            key: SnapshotAdditionalContextKey.self,
            value: SnapshotMetadataValue.dictionary(from: context)
        )
    }
}
