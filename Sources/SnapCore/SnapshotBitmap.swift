import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// A platform-neutral rendered snapshot.
///
/// `CGImage` instances are immutable, so a bitmap can safely move to the
/// export queue after the platform renderer finishes creating it.
@frozen
public struct SnapshotBitmap: @unchecked Sendable {
    /// The rendered pixels.
    public let cgImage: CGImage

    /// Pixels per logical point.
    public let scale: CGFloat

    /// The logical size of the rendered preview in points.
    public let size: CGSize

    public init(cgImage: CGImage, scale: CGFloat, size: CGSize) {
        self.cgImage = cgImage
        self.scale = scale
        self.size = size
    }

    /// Encodes the bitmap as PNG data without depending on AppKit or UIKit.
    public func pngData() -> Data? {
        guard let data = CFDataCreateMutable(nil, 0) else {
            return nil
        }
        guard
            let destination = CGImageDestinationCreateWithData(
                data,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }
        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return data as Data
    }
}
