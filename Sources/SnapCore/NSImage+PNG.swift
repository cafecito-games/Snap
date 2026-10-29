import AppKit

extension NSImage {
    /// Encodes the image as PNG data.
    public func pngData() -> Data? {
        guard
            let tiffRepresentation,
            let bitmapRepresentation = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }
        return bitmapRepresentation.representation(using: .png, properties: [:])
    }
}
