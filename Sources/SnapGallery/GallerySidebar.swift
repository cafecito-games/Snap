import SwiftUI

struct GallerySidebar: View {
    @Bindable var model: GalleryModel

    private var selection: Binding<String?> {
        Binding(
            get: { model.selectedComponentID },
            set: { model.selectComponent($0) }
        )
    }

    var body: some View {
        List(selection: selection) {
            ForEach(model.filteredModules) { module in
                Section(module.name) {
                    ForEach(module.components) { component in
                        Label {
                            HStack(spacing: 8) {
                                Text(component.name)
                                    .lineLimit(1)
                                Spacer(minLength: 4)
                                Text(component.stories.count, format: .number)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        } icon: {
                            Image(systemName: "square.stack.3d.up")
                                .foregroundStyle(.secondary)
                        }
                        .tag(component.id)
                        .accessibilityLabel(
                            "\(component.name), \(component.stories.count) previews"
                        )
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Snap Gallery")
        .searchable(text: $model.searchText, placement: .sidebar, prompt: "Components")
        .overlay {
            if model.filteredModules.isEmpty {
                ContentUnavailableView.search(text: model.searchText)
            }
        }
    }
}
