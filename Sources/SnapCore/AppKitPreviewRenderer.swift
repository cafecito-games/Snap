import AppKit
import CoreFoundation
import SwiftUI
import SnapModels

/// Renders previews offscreen and captures them as images.
///
/// The renderer keeps one borderless window alive for the lifetime of a test
/// run and swaps in a fresh hosting controller per preview.
@MainActor
public final class AppKitPreviewRenderer {
    /// The default box proposed to previews that do not declare a fixed size.
    /// Previews with explicit `.frame` modifiers constrain themselves and are
    /// unaffected by this proposal.
    static let defaultProposedSize = NSSize(width: 800, height: 400)

    /// The result of one render pass.
    @frozen
    public struct Outcome {
        /// The captured image, or `nil` when capture was skipped or failed.
        public let image: NSImage?

        /// The color scheme the preview declared through
        /// `.preferredColorScheme(_:)`, if any.
        public let colorScheme: ColorScheme?

        /// Per-preview preferences declared with the `SnapPreferences`
        /// modifiers, when that library is linked into the process.
        public let preferences: SnapshotPreferenceSnapshot

        /// The failure that prevented image capture, if any.
        public let captureError: Error?
    }

    private let window: SnapshotWindow
    private var widthAnchor: NSLayoutConstraint?
    private var heightAnchor: NSLayoutConstraint?

    public init() {
        window = SnapshotWindow(
            contentRect: NSRect(
                origin: .zero,
                size: Self.defaultProposedSize
            )
        )
        // The window only hosts offscreen layout. Ordering it in a running app
        // would steal focus when SnapGallery renders a thumbnail.
    }

    public func render(
        _ preview: RenderablePreview,
        captureImage: Bool = true
    ) -> Outcome {
        let prepared = prepare(preview)
        settleLayout()
        return finish(prepared, captureImage: captureImage)
    }

    /// Renders from a running application without blocking SwiftUI's commit
    /// cycle. Preferences such as tags are delivered after control returns to
    /// the app event loop, so gallery rendering must suspend before capture.
    package func renderForGallery(
        _ preview: RenderablePreview,
        captureImage: Bool = true
    ) async -> Outcome {
        let prepared = prepare(preview)
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))
        return finish(prepared, captureImage: captureImage)
    }

    private func prepare(_ preview: RenderablePreview) -> PreparedRender {
        let schemeBox = PreferredSchemeBox()

        var rootView: AnyView = AnyView(
            PreviewHostingView(preview: preview) { scheme in
                schemeBox.value = scheme
            }
        )
        if let wrapWithPreferences = SnapshotPreferenceReader.wrapWithPreferences {
            rootView = AnyView(wrapWithPreferences(rootView))
        }

        let hostingController = NSHostingController(rootView: rootView)
        if #available(macOS 13.0, *) {
            hostingController.sizingOptions = .intrinsicContentSize
        }

        // Swap in a clean content view controller so constraints and state
        // from the previous preview cannot leak into this render.
        window.contentViewController = NSViewController()
        window.setContentSize(Self.defaultProposedSize)
        window.contentViewController = hostingController

        let proposedSize = proposedSize(for: preview.layout)
        let fittingSize = hostingController.sizeThatFits(in: proposedSize)
        applySizeConstraints(
            to: hostingController.view,
            width: fittingSize.width,
            height: fittingSize.height
        )
        hostingController.view.layoutSubtreeIfNeeded()
        hostingController.view.needsDisplay = true
        hostingController.view.displayIfNeeded()

        return PreparedRender(
            hostingController: hostingController,
            schemeBox: schemeBox
        )
    }

    private func finish(
        _ prepared: PreparedRender,
        captureImage: Bool
    ) -> Outcome {
        let preferences = SnapshotPreferenceReader.readSnapshot()

        guard captureImage else {
            return Outcome(
                image: nil,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: nil
            )
        }

        let mode = preferences.renderingMode ?? .view
        do {
            let image = try capture(
                mode: mode,
                hostingController: prepared.hostingController
            )
            return Outcome(
                image: image,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: nil
            )
        } catch {
            return Outcome(
                image: nil,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: error
            )
        }
    }

    private struct PreparedRender {
        let hostingController: NSHostingController<AnyView>
        let schemeBox: PreferredSchemeBox
    }

    private func proposedSize(for layout: PreviewLayout) -> NSSize {
        switch layout {
        case .fixed(let width, let height):
            return NSSize(width: width, height: height)
        case .device, .sizeThatFits:
            return Self.defaultProposedSize
        default:
            return Self.defaultProposedSize
        }
    }

    private func applySizeConstraints(to view: NSView, width: CGFloat, height: CGFloat) {
        widthAnchor?.isActive = false
        heightAnchor?.isActive = false
        widthAnchor = view.widthAnchor.constraint(equalToConstant: width)
        heightAnchor = view.heightAnchor.constraint(equalToConstant: height)
        widthAnchor?.isActive = true
        heightAnchor?.isActive = true
    }

    /// Gives asynchronous layout and preference propagation one turn of the
    /// run loop to settle before pixels are captured.
    private func settleLayout() {
        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.05, false)
    }

    private func capture(
        mode: SnapshotRenderingMode,
        hostingController: NSHostingController<AnyView>
    ) throws -> NSImage {
        switch mode {
        case .view:
            guard let image = hostingController.view.snapshotImage() else {
                throw CaptureError.viewCaptureFailed
            }
            return image
        case .layer:
            guard let image = hostingController.view.layerSnapshotImage() else {
                throw CaptureError.layerCaptureFailed
            }
            return image
        }
    }

    enum CaptureError: Error, CustomStringConvertible {
        case viewCaptureFailed
        case layerCaptureFailed

        var description: String {
            switch self {
            case .viewCaptureFailed:
                return "Capturing the hosting view through cacheDisplay failed."
            case .layerCaptureFailed:
                return "Capturing the hosting view's layer tree failed."
            }
        }
    }
}

/// A borderless, transparent window used purely as a hosting surface.
final class SnapshotWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = .clear
    }
}

/// Captures the color scheme a preview declares with
/// `.preferredColorScheme(_:)` and re-applies it as an environment override.
///
/// Xcode's preview canvas performs this conversion itself; without it a
/// `.preferredColorScheme(.dark)` preview would still render in the ambient
/// appearance inside an offscreen window.
private final class PreferredSchemeBox {
    var value: ColorScheme?
}
