#if canImport(UIKit)
import SnapModels
import SwiftUI
import UIKit

/// Renders previews inside an isolated UIKit host window.
///
/// A renderer resolves a window scene only when rendering, so consumers can
/// construct it before an app-hosted test or gallery finishes connecting its
/// scene. Each pass creates and tears down a fresh offscreen window to prevent
/// state from leaking between previews.
@MainActor
public final class UIKitPreviewRenderer: PreviewRenderer {
    /// The default viewport proposed to previews without a fixed layout.
    public static let defaultProposedSize = CGSize(width: 390, height: 844)

    /// Compatibility name for the shared render outcome.
    public typealias Outcome = PreviewRenderOutcome

    private weak var preferredWindowScene: UIWindowScene?

    /// Creates a renderer that uses `windowScene` when supplied and otherwise
    /// resolves the foreground scene at render time.
    public init(windowScene: UIWindowScene? = nil) {
        preferredWindowScene = windowScene
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
        guard let windowScene = resolvedWindowScene else {
            return Outcome(
                bitmap: nil,
                colorScheme: nil,
                preferences: .empty,
                captureError: .missingWindowScene
            )
        }
        if let scale = request.configuration.scale, scale <= 0 {
            return Outcome(
                bitmap: nil,
                colorScheme: nil,
                preferences: .empty,
                captureError: .invalidScale(scale)
            )
        }

        let prepared = prepare(request: request, windowScene: windowScene)
        defer { prepared.tearDown() }

        request.configuration.settling.settleSynchronously()
        prepared.hostingController.view.layoutIfNeeded()
        let preferences = SnapshotPreferenceReader.readSnapshot()

        guard request.capturesBitmap else {
            return Outcome(
                bitmap: nil,
                colorScheme: prepared.schemeBox.value,
                preferences: preferences,
                captureError: nil
            )
        }

        do {
            let bitmap = try capture(
                prepared.hostingController.view,
                mode: preferences.renderingMode ?? .view,
                scale: request.configuration.scale ?? windowScene.screen.scale
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

    private var resolvedWindowScene: UIWindowScene? {
        if let preferredWindowScene {
            return preferredWindowScene
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }
            ?? scenes.first
    }

    private func prepare(
        request: PreviewRenderRequest,
        windowScene: UIWindowScene
    ) -> PreparedRender {
        let schemeBox = UIKitPreferredSchemeBox()
        var rootView = AnyView(
            PreviewHostingView(
                preview: request.preview,
                colorSchemeOverride: request.configuration.colorScheme
            ) { scheme in
                schemeBox.value = scheme
            }
        )
        if let wrapWithPreferences = SnapshotPreferenceReader.wrapWithPreferences {
            rootView = AnyView(wrapWithPreferences(rootView))
        }

        let hostingController = UIHostingController(rootView: rootView)
        hostingController.overrideUserInterfaceStyle = userInterfaceStyle(
            for: request.configuration.colorScheme
        )

        let proposedSize = request.configuration.viewport
            ?? proposedSize(for: request.preview.layout)
        let fittingSize = hostingController.sizeThatFits(in: proposedSize)
        let requestedSize = request.configuration.viewport ?? fittingSize
        let renderSize = CGSize(
            width: max(1, requestedSize.width),
            height: max(1, requestedSize.height)
        )

        let window = UIWindow(windowScene: windowScene)
        window.windowLevel = UIWindow.Level(rawValue: UIWindow.Level.normal.rawValue - 1)
        window.frame = CGRect(
            x: windowScene.screen.bounds.maxX + renderSize.width,
            y: windowScene.screen.bounds.maxY + renderSize.height,
            width: renderSize.width,
            height: renderSize.height
        )
        window.backgroundColor = .clear
        window.rootViewController = hostingController
        window.isHidden = false

        hostingController.view.frame = CGRect(origin: .zero, size: renderSize)
        hostingController.view.backgroundColor = .clear
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()

        return PreparedRender(
            window: window,
            hostingController: hostingController,
            schemeBox: schemeBox
        )
    }

    private func proposedSize(for layout: PreviewLayout) -> CGSize {
        switch layout {
        case .fixed(let width, let height):
            return CGSize(width: width, height: height)
        case .device, .sizeThatFits:
            return Self.defaultProposedSize
        default:
            return Self.defaultProposedSize
        }
    }

    private func userInterfaceStyle(for colorScheme: ColorScheme?) -> UIUserInterfaceStyle {
        switch colorScheme {
        case .light:
            return .light
        case .dark:
            return .dark
        case nil:
            return .unspecified
        @unknown default:
            return .unspecified
        }
    }

    private func capture(
        _ view: UIView,
        mode: SnapshotRenderingMode,
        scale: CGFloat
    ) throws -> SnapshotBitmap {
        guard view.bounds.width > 0, view.bounds.height > 0 else {
            throw PreviewRenderError.emptyBounds
        }
        guard scale > 0 else {
            throw PreviewRenderError.invalidScale(scale)
        }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds, format: format)

        let image: UIImage
        switch mode {
        case .view:
            var completed = false
            image = renderer.image { _ in
                completed = view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
            }
            guard completed else {
                throw PreviewRenderError.viewCaptureFailed
            }
        case .layer:
            image = renderer.image { context in
                view.layer.render(in: context.cgContext)
            }
        }

        guard let cgImage = image.cgImage else {
            throw PreviewRenderError.bitmapCreationFailed
        }
        return SnapshotBitmap(cgImage: cgImage, scale: image.scale, size: image.size)
    }

    private struct PreparedRender {
        let window: UIWindow
        let hostingController: UIHostingController<AnyView>
        let schemeBox: UIKitPreferredSchemeBox

        @MainActor
        func tearDown() {
            window.isHidden = true
            window.rootViewController = nil
        }
    }
}

private final class UIKitPreferredSchemeBox {
    var value: ColorScheme?
}
#endif
