import Foundation

/// Selects the pixel-capture backend used to rasterize a preview.
@frozen
public enum SnapshotRenderingMode: Int, Sendable, Equatable {
    /// Renders through the platform hosting view's hierarchy-capture API, the
    /// default and most deterministic path.
    case view = 0
    /// Renders the backing layer tree through `CALayer.render(in:)`.
    /// Sometimes captures materials and effects that the view path misses.
    case layer = 1
}
