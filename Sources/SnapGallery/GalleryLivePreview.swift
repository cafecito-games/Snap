import AppKit
import SnapCore
import SwiftUI

/// Hosts the live story through AppKit so its proposed and fitted sizes match
/// `AppKitPreviewRenderer` while preserving the story's interactive state.
struct GalleryLivePreview: NSViewControllerRepresentable {
    let story: GalleryStory
    let appearance: GalleryAppearance
    let generation: Int

    func makeCoordinator() -> Coordinator {
        Coordinator(contentID: contentID)
    }

    func makeNSViewController(context: Context) -> NSHostingController<AnyView> {
        let controller = NSHostingController(rootView: rootView)
        controller.sizingOptions = .intrinsicContentSize
        return controller
    }

    func updateNSViewController(
        _ controller: NSHostingController<AnyView>,
        context: Context
    ) {
        guard context.coordinator.contentID != contentID else { return }
        context.coordinator.contentID = contentID
        controller.rootView = rootView
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsViewController controller: NSHostingController<AnyView>,
        context: Context
    ) -> CGSize? {
        controller.sizeThatFits(in: GalleryPreviewSizing.proposedSize(for: story.preview.layout))
    }

    private var contentID: String {
        GalleryLivePreviewIdentity.value(
            storyID: story.id,
            appearance: appearance,
            generation: generation
        )
    }

    private var rootView: AnyView {
        AnyView(
            PreviewHostingView(
                preview: story.preview,
                colorSchemeOverride: appearance.colorScheme
            )
        )
    }

    final class Coordinator {
        var contentID: String

        init(contentID: String) {
            self.contentID = contentID
        }
    }
}

enum GalleryLivePreviewIdentity {
    static func value(
        storyID: String,
        appearance: GalleryAppearance,
        generation: Int
    ) -> String {
        "\(storyID):\(appearance.rawValue):\(generation)"
    }
}

enum GalleryPreviewSizing {
    static let defaultProposedSize = CGSize(width: 800, height: 400)

    static func proposedSize(for layout: PreviewLayout) -> CGSize {
        switch layout {
        case .fixed(let width, let height):
            return CGSize(width: width, height: height)
        case .device, .sizeThatFits:
            return defaultProposedSize
        default:
            return defaultProposedSize
        }
    }
}
