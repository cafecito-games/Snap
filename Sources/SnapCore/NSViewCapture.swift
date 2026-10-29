import AppKit
import CoreGraphics
import SnapModels

extension NSView {
    /// Captures the view through `cacheDisplay`, the most deterministic
    /// capture path for regular SwiftUI content.
    func snapshotImage() -> NSImage? {
        guard bounds.width > 0, bounds.height > 0 else {
            return nil
        }
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else {
            return nil
        }
        bitmapRep.size = bounds.size
        cacheDisplay(in: bounds, to: bitmapRep)
        let image = NSImage(size: bounds.size)
        image.addRepresentation(bitmapRep)
        return image
    }

    /// Captures the view's layer tree into a bitmap context.
    func layerSnapshotImage() -> NSImage? {
        let scale = window?.backingScaleFactor ?? 1
        let pixelWidth = Int(bounds.width * scale)
        let pixelHeight = Int(bounds.height * scale)
        guard pixelWidth > 0, pixelHeight > 0 else {
            return nil
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
            return nil
        }

        context.translateBy(x: 0, y: CGFloat(pixelHeight))
        context.scaleBy(x: scale, y: -scale)
        (layer?.presentation() ?? layer)?.render(in: context)
        guard let cgImage = context.makeImage() else {
            return nil
        }
        return NSImage(cgImage: cgImage, size: bounds.size)
    }
}

