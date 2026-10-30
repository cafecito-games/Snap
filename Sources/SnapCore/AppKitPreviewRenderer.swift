#if canImport(AppKit)
import AppKit
import SwiftUI
import SnapModels

/// Renders previews offscreen and captures them as images.
///
/// The renderer keeps one borderless window alive for the lifetime of a test
/// run and swaps in a fresh hosting controller per preview.
@MainActor
public final class AppKitPreviewRenderer: PreviewRenderer {
    /// The default box proposed to previews that do not declare a fixed size.
    /// Previews with explicit `.frame` modifiers constrain themselves and are
    /// unaffected by this proposal.
    static let defaultProposedSize = NSSize(width: 800, height: 400)

    /// Compatibility name for the shared render outcome.
    public typealias Outcome = PreviewRenderOutcome

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
        render(
            PreviewRenderRequest(
                preview: preview,
                capturesBitmap: captureImage
            )
        )
    }

    public func render(_ request: PreviewRenderRequest) -> PreviewRenderOutcome {
        let prepared = prepare(
            request.preview,
            configuration: request.configuration
        )
        request.configuration.settling.settleSynchronously()
        return finish(prepared, request: request)
    }

    /// Renders from a running application without blocking SwiftUI's commit
    /// cycle. Preferences such as tags are delivered after control returns to
    /// the app event loop, so gallery rendering must suspend before capture.
    package func renderForGallery(
        _ preview: RenderablePreview,
        captureImage: Bool = true
    ) async -> Outcome {
        let request = PreviewRenderRequest(
            preview: preview,
            capturesBitmap: captureImage
        )
        let prepared = prepare(
            request.preview,
            configuration: request.configuration
        )
        await request.configuration.settling.settleAsynchronously()
        return finish(prepared, request: request)
    }

    private func prepare(
        _ preview: RenderablePreview,
        configuration: PreviewRenderConfiguration
    ) -> PreparedRender {
        let schemeBox = PreferredSchemeBox()

        var rootView: AnyView = AnyView(
            PreviewHostingView(
                preview: preview,
                colorSchemeOverride: configuration.colorScheme
            ) { scheme in
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

        let proposedSize = configuration.viewport ?? proposedSize(for: preview.layout)
        let fittingSize = hostingController.sizeThatFits(in: proposedSize)
        let renderSize = configuration.viewport ?? fittingSize
        applySizeConstraints(
            to: hostingController.view,
            width: renderSize.width,
            height: renderSize.height
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
        request: PreviewRenderRequest
    ) -> Outcome {
        let preferences = SnapshotPreferenceReader.readSnapshot()

        guard request.capturesBitmap else {
            return Outcome(
                bitmap: nil,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: nil
            )
        }

        let mode = preferences.renderingMode ?? .view
        do {
            let bitmap = try capture(
                mode: mode,
                hostingController: prepared.hostingController,
                scale: request.configuration.scale
            )
            return Outcome(
                bitmap: bitmap,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: nil
            )
        } catch let error as PreviewRenderError {
            return Outcome(
                bitmap: nil,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: error
            )
        } catch {
            return Outcome(
                bitmap: nil,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: .bitmapCreationFailed
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

    private func capture(
        mode: SnapshotRenderingMode,
        hostingController: NSHostingController<AnyView>,
        scale: CGFloat?
    ) throws -> SnapshotBitmap {
        switch mode {
        case .view:
            return try hostingController.view.snapshotBitmap(scale: scale)
        case .layer:
            return try hostingController.view.layerSnapshotBitmap(scale: scale)
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
#endif
