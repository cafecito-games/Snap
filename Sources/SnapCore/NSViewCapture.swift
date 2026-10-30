#if canImport(AppKit)
import AppKit
import CoreGraphics
import SnapModels

extension NSView {
    /// Captures the view through `cacheDisplay`, the most deterministic
    /// capture path for regular SwiftUI content.
    func snapshotBitmap(scale explicitScale: CGFloat?) throws -> SnapshotBitmap {
        guard bounds.width > 0, bounds.height > 0 else {
            throw PreviewRenderError.emptyBounds
        }
        let scale = explicitScale ?? window?.backingScaleFactor ?? 1
        guard scale > 0 else {
            throw PreviewRenderError.invalidScale(scale)
        }
        guard
            let bitmapRep = NSBitmapImageRep(
                bitmapDataPlanes: nil,
                pixelsWide: Int(ceil(bounds.width * scale)),
                pixelsHigh: Int(ceil(bounds.height * scale)),
                bitsPerSample: 8,
                samplesPerPixel: 4,
                hasAlpha: true,
                isPlanar: false,
                colorSpaceName: .deviceRGB,
                bytesPerRow: 0,
                bitsPerPixel: 0
            )
        else {
            throw PreviewRenderError.bitmapCreationFailed
        }
        bitmapRep.size = bounds.size
        cacheDisplay(in: bounds, to: bitmapRep)
        guard let cgImage = bitmapRep.cgImage else {
            throw PreviewRenderError.bitmapCreationFailed
        }
        return SnapshotBitmap(cgImage: cgImage, scale: scale, size: bounds.size)
    }

    /// Captures the view's layer tree into a bitmap context.
    func layerSnapshotBitmap(scale explicitScale: CGFloat?) throws -> SnapshotBitmap {
        guard bounds.width > 0, bounds.height > 0 else {
            throw PreviewRenderError.emptyBounds
        }
        let scale = explicitScale ?? window?.backingScaleFactor ?? 1
        guard scale > 0 else {
            throw PreviewRenderError.invalidScale(scale)
        }
        let pixelWidth = Int(bounds.width * scale)
        let pixelHeight = Int(bounds.height * scale)
        guard pixelWidth > 0, pixelHeight > 0 else {
            throw PreviewRenderError.emptyBounds
        }
        guard
            let context = CGContext(
                data: nil,
                width: pixelWidth,
                height: pixelHeight,
                bitsPerComponent: 8,
                bytesPerRow: pixelWidth * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else {
            throw PreviewRenderError.bitmapCreationFailed
        }

        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: scale, y: -scale)
        (layer?.presentation() ?? layer)?.render(in: context)
        guard let cgImage = context.makeImage() else {
            throw PreviewRenderError.layerCaptureFailed
        }
        return SnapshotBitmap(cgImage: cgImage, scale: scale, size: bounds.size)
    }
}
#endif

