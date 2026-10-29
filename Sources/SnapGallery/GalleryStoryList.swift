import AppKit
import SwiftUI

struct GalleryStoryList: View {
    @Bindable var model: GalleryModel

    private var selection: Binding<String?> {
        Binding(
            get: { model.selectedStoryID },
            set: { model.selectStory($0) }
        )
    }

    var body: some View {
        if let component = model.selectedComponent {
            List(component.stories, selection: selection) { story in
                GalleryStoryRow(
                    story: story,
                    previewImage: model.thumbnail(for: story.id),
                    result: model.renderResults[story.id]
                )
                .tag(story.id)
                .task(id: story.id) {
                    model.renderIfNeeded(story)
                }
            }
            .listStyle(.inset)
            .navigationTitle(component.name)
        } else {
            ContentUnavailableView(
                "No Previews",
                systemImage: "rectangle.stack.badge.questionmark",
                description: Text(
                    model.catalog.modules.isEmpty
                        ? "No compiled previews were found in the selected modules."
                        : "Choose a component from the sidebar."
                )
            )
            .navigationTitle("Previews")
        }
    }
}

private struct GalleryStoryRow: View {
    let story: GalleryStory
    let previewImage: NSImage?
    let result: GalleryRenderResult?

    var body: some View {
        HStack(spacing: 12) {
            thumbnailContent
                .frame(width: 92, height: 62)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(story.name)
                    .font(.body.weight(.medium))
                    .lineLimit(2)
                Text(story.layoutDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(story.name), \(story.layoutDescription)")
    }

    @ViewBuilder
    private var thumbnailContent: some View {
        if let previewImage {
            Image(nsImage: previewImage)
                .resizable()
                .scaledToFit()
                .padding(5)
        } else if result?.errorDescription != nil {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.secondary)
        } else {
            ProgressView()
                .controlSize(.small)
        }
    }
}
