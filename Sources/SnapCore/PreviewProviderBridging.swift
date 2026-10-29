import SwiftUI

/// Bridges `PreviewProvider`-conforming types into preview containers.
///
/// A provider can declare several previews in `static var previews`; each
/// child is selected with SwiftUI's private variadic view tree, which is the
/// only supported way to address a single element of a `TupleView`.
@MainActor
enum PreviewProviderBridging {
    static func makeContainer<P: PreviewProvider>(
        typeName: String,
        provider: P.Type
    ) -> PreviewContainer {
        let items = provider._allPreviews
        let previews = items.map { item in
            RenderablePreview(
                containerTypeName: typeName,
                fileID: nil,
                line: nil,
                displayName: item.displayName,
                index: item.id,
                layout: item.layout,
                makeView: {
                    ChildSelectionTree(position: item.id) {
                        provider.previews
                    }
                }
            )
        }
        return PreviewContainer(typeName: typeName, fileID: nil, line: nil, previews: previews)
    }
}

/// Renders only the child at `position` from a multi-child view builder.
private struct ChildSelector: _VariadicView_MultiViewRoot {
    let position: Int

    func body(children: _VariadicView.Children) -> some View {
        children[position]
    }
}

private struct ChildSelectionTree<Content: View>: View {
    let position: Int
    let content: Content

    init(position: Int, @ViewBuilder content: () -> Content) {
        self.position = position
        self.content = content()
    }

    var body: some View {
        _VariadicView.Tree(ChildSelector(position: position)) {
            content
        }
    }
}
