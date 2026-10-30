import CoreFoundation
import CoreGraphics
import Foundation
import SnapModels
import SwiftUI

/// How long a renderer allows SwiftUI layout and preferences to settle before
/// it captures pixels.
@frozen
public enum PreviewRenderSettling: Sendable, Equatable {
    /// Capture immediately after synchronous layout.
    case immediate

    /// Run the event loop for up to the given number of seconds.
    case runLoop(seconds: TimeInterval)

    /// Snap's default settling policy.
    public static let standard = PreviewRenderSettling.runLoop(seconds: 0.05)
}
/// Platform-neutral controls for one preview render.
@frozen
public struct PreviewRenderConfiguration: Sendable, Equatable {
    /// An explicit logical viewport. `nil` honors the preview's layout and the
    /// renderer's platform default.
    public var viewport: CGSize?

    /// An explicit pixels-per-point scale. `nil` uses the hosting display.
    public var scale: CGFloat?

    /// An appearance override. `nil` honors the preview and host appearance.
    public var colorScheme: ColorScheme?

    /// The policy used to allow asynchronous view state to settle.
    public var settling: PreviewRenderSettling

    public init(
        viewport: CGSize? = nil,
        scale: CGFloat? = nil,
        colorScheme: ColorScheme? = nil,
        settling: PreviewRenderSettling = .standard
    ) {
        self.viewport = viewport
        self.scale = scale
        self.colorScheme = colorScheme
        self.settling = settling
    }
}

/// Everything a renderer needs for one isolated preview pass.
@MainActor
public struct PreviewRenderRequest {
    public let preview: RenderablePreview
    public var configuration: PreviewRenderConfiguration
    public var capturesBitmap: Bool

    public init(
        preview: RenderablePreview,
        configuration: PreviewRenderConfiguration = PreviewRenderConfiguration(),
        capturesBitmap: Bool = true
    ) {
        self.preview = preview
        self.configuration = configuration
        self.capturesBitmap = capturesBitmap
    }
}

/// A renderer failure that can be shown in XCTest or a gallery diagnostic.
@frozen
public enum PreviewRenderError: Error, Sendable, Equatable, CustomStringConvertible {
    case missingWindowScene
    case invalidScale(CGFloat)
    case emptyBounds
    case bitmapCreationFailed
    case viewCaptureFailed
    case layerCaptureFailed

    public var description: String {
        switch self {
        case .missingWindowScene:
            return "UIKit rendering requires an app-hosted test or gallery with an active window scene."
        case .invalidScale(let scale):
            return "The requested snapshot scale must be greater than zero; received \(scale)."
        case .emptyBounds:
            return "The hosted preview has empty bounds."
        case .bitmapCreationFailed:
            return "The renderer could not create a bitmap for the hosted preview."
        case .viewCaptureFailed:
            return "Capturing the platform view hierarchy failed."
        case .layerCaptureFailed:
            return "Capturing the platform layer tree failed."
        }
    }
}

/// The platform-neutral result of one render pass.
@frozen
public struct PreviewRenderOutcome {
    /// Captured pixels, or `nil` when capture was skipped or failed.
    public let bitmap: SnapshotBitmap?

    /// The color scheme declared by the preview, if any.
    public let colorScheme: ColorScheme?

    /// Preferences declared through `SnapPreferences` modifiers.
    public let preferences: SnapshotPreferenceSnapshot

    /// The failure that prevented capture, if any.
    public let captureError: PreviewRenderError?

    package init(
        bitmap: SnapshotBitmap?,
        colorScheme: ColorScheme?,
        preferences: SnapshotPreferenceSnapshot,
        captureError: PreviewRenderError?
    ) {
        self.bitmap = bitmap
        self.colorScheme = colorScheme
        self.preferences = preferences
        self.captureError = captureError
    }
}

/// A platform backend capable of rendering compiled previews.
@MainActor
public protocol PreviewRenderer: AnyObject {
    func render(_ request: PreviewRenderRequest) -> PreviewRenderOutcome
}

extension PreviewRenderSettling {
    func settleSynchronously() {
        switch self {
        case .immediate:
            return
        case .runLoop(let seconds):
            guard seconds > 0 else { return }
            CFRunLoopRunInMode(CFRunLoopMode.defaultMode, seconds, false)
        }
    }

    func settleAsynchronously() async {
        await Task.yield()
        switch self {
        case .immediate:
            return
        case .runLoop(let seconds):
            guard seconds > 0 else { return }
            try? await Task.sleep(for: .seconds(seconds))
        }
    }
}
