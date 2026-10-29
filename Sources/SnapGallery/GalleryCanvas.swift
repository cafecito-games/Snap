import AppKit
import SnapCore
import SwiftUI

struct GalleryCanvas: View {
    @Bindable var model: GalleryModel

    var body: some View {
        Group {
            if let story = model.selectedStory {
                GeometryReader { geometry in
                    ScrollViewReader { scrollProxy in
                        ScrollView([.horizontal, .vertical]) {
                            ZStack {
                                canvasBackground

                                if model.showsGrid {
                                    CanvasGrid()
                                }

                                ScaledPreview(zoom: model.zoom) {
                                    livePreview(story)
                                }
                                .id(story.id)
                                .padding(80)
                            }
                            .frame(
                                minWidth: geometry.size.width,
                                minHeight: geometry.size.height
                            )
                        }
                        .defaultScrollAnchor(.center)
                        .scrollIndicators(.automatic)
                        .onChange(of: model.previewGeneration) {
                            Task { @MainActor in
                                await Task.yield()
                                scrollProxy.scrollTo(story.id, anchor: .center)
                            }
                        }
                        .onChange(of: story.id, initial: true) {
                            Task { @MainActor in
                                await Task.yield()
                                scrollProxy.scrollTo(story.id, anchor: .center)
                            }
                        }
                    }
                }
                .navigationTitle(story.name)
                .task(id: story.id) {
                    model.renderIfNeeded(story)
                }
            } else {
                ContentUnavailableView(
                    "Select a Preview",
                    systemImage: "cursorarrow.click.2",
                    description: Text("Choose a component state to open it on the canvas.")
                )
                .navigationTitle("Canvas")
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func livePreview(_ story: GalleryStory) -> some View {
        GalleryLivePreview(
            story: story,
            appearance: model.appearance,
            generation: model.previewGeneration
        )
        .id(
            GalleryLivePreviewIdentity.value(
                storyID: story.id,
                appearance: model.appearance,
                generation: model.previewGeneration
            )
        )
        .shadow(color: .black.opacity(0.12), radius: 18, x: 0, y: 7)
    }

    @ViewBuilder
    private var canvasBackground: some View {
        switch model.canvasBackground {
        case .canvas:
            Color(nsColor: .galleryCanvasBackground)
        case .white:
            Color.white
        case .black:
            Color.black
        case .checkerboard:
            CheckerboardCanvas()
        }
    }
}

struct GalleryScaledPreviewLayout {
    static func frameSize(contentSize: CGSize, zoom: Double) -> CGSize {
        CGSize(
            width: max(0, contentSize.width * zoom),
            height: max(0, contentSize.height * zoom)
        )
    }
}

private struct ScaledPreview<Content: View>: View {
    let zoom: Double
    @ViewBuilder let content: Content

    @State private var contentSize = CGSize.zero

    init(zoom: Double, @ViewBuilder content: () -> Content) {
        self.zoom = zoom
        self.content = content()
    }

    var body: some View {
        let scaledSize = GalleryScaledPreviewLayout.frameSize(
            contentSize: contentSize,
            zoom: zoom
        )

        content
            .onGeometryChange(for: CGSize.self) { proxy in
                proxy.size
            } action: { size in
                contentSize = size
            }
            .scaleEffect(zoom)
            .frame(width: scaledSize.width, height: scaledSize.height)
    }
}

private extension NSColor {
    static let galleryCanvasBackground = NSColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return NSColor(deviceWhite: 0.13, alpha: 1)
        }
        return NSColor(deviceWhite: 0.91, alpha: 1)
    }
}

private struct CheckerboardCanvas: View {
    private let squareSize = 12.0

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white))
            let columns = Int(ceil(size.width / squareSize))
            let rows = Int(ceil(size.height / squareSize))

            for row in 0..<rows {
                for column in 0..<columns where (row + column).isMultiple(of: 2) {
                    let rect = CGRect(
                        x: Double(column) * squareSize,
                        y: Double(row) * squareSize,
                        width: squareSize,
                        height: squareSize
                    )
                    context.fill(Path(rect), with: .color(Color(nsColor: .quaternaryLabelColor)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct CanvasGrid: View {
    private let spacing = 20.0

    var body: some View {
        Canvas { context, size in
            var path = Path()
            stride(from: 0.0, through: size.width, by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: 0.0, through: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(
                path,
                with: .color(Color(nsColor: .separatorColor).opacity(0.4)),
                lineWidth: 0.5
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
