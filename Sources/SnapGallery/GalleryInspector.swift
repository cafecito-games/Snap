import SnapModels
import SwiftUI

struct GalleryInspector: View {
    @Bindable var model: GalleryModel

    var body: some View {
        if let story = model.selectedStory {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    inspectorHeader(story)

                    InspectorSection("Source") {
                        InspectorValue(
                            label: "Location",
                            value: story.sourceDescription ?? "Runtime provider"
                        )
                    }

                    InspectorSection("Layout") {
                        InspectorValue(label: "Mode", value: story.layoutDescription)
                        if let scheme = model.renderResults[story.id]?.colorScheme {
                            InspectorValue(
                                label: "Preferred appearance",
                                value: scheme == .dark ? "Dark" : "Light"
                            )
                        }
                    }

                    preferences(for: story)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .task(id: story.id) {
                model.renderIfNeeded(story)
            }
        } else {
            ContentUnavailableView(
                "No Selection",
                systemImage: "sidebar.trailing",
                description: Text("Select a preview to inspect its metadata.")
            )
        }
    }

    private func inspectorHeader(_ story: GalleryStory) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(story.name)
                .font(.title3.weight(.semibold))
                .textSelection(.enabled)
            if let component = model.selectedComponent {
                Text("\(component.moduleName) · \(component.name)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    @ViewBuilder
    private func preferences(for story: GalleryStory) -> some View {
        if let result = model.renderResults[story.id] {
            if let error = result.errorDescription {
                InspectorSection("Rendering") {
                    Label(error, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            if !result.preferences.tags.isEmpty {
                InspectorSection("Tags") {
                    ForEach(result.preferences.tags.keys.sorted(), id: \.self) { key in
                        InspectorValue(
                            label: key,
                            value: result.preferences.tags[key] ?? ""
                        )
                    }
                }
            }

            if !result.preferences.additionalContext.isEmpty {
                InspectorSection("Context") {
                    ForEach(
                        flattened(result.preferences.additionalContext),
                        id: \.key
                    ) { entry in
                        InspectorValue(label: entry.key, value: entry.value)
                    }
                }
            }

            if result.preferences.tags.isEmpty,
               result.preferences.additionalContext.isEmpty,
               result.errorDescription == nil
            {
                InspectorSection("Metadata") {
                    Text("No tags or additional context")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            InspectorSection("Metadata") {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Reading preview metadata…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func flattened(
        _ values: [String: SnapshotMetadataValue],
        prefix: String? = nil
    ) -> [(key: String, value: String)] {
        values.keys.sorted().flatMap { key -> [(key: String, value: String)] in
            guard let value = values[key] else { return [] }
            let qualifiedKey = [prefix, key].compactMap { $0 }.joined(separator: ".")
            switch value {
            case .string(let value):
                return [(qualifiedKey, value)]
            case .number(let value):
                return [(qualifiedKey, value.formatted())]
            case .bool(let value):
                return [(qualifiedKey, value ? "true" : "false")]
            case .object(let nested):
                return flattened(nested, prefix: qualifiedKey)
            }
        }
    }
}

private struct InspectorSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

private struct InspectorValue: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label) {
            Text(value)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
        .font(.caption)
    }
}
