import SwiftUI

/// Hosts one preview while keeping its preferred appearance inside the
/// preview rather than allowing it to change an enclosing app window.
///
/// Package access lets SnapGallery reuse the exact hosting behavior used by
/// snapshot rendering without exposing preview construction as public API.
@MainActor
package struct PreviewHostingView: View {
    @State private var preferredScheme: ColorScheme?
    @Environment(\.colorScheme) private var ambientScheme

    private let preview: RenderablePreview
    private let colorSchemeOverride: ColorScheme?
    private let onPreferredSchemeChange: @MainActor (ColorScheme?) -> Void

    package init(
        preview: RenderablePreview,
        colorSchemeOverride: ColorScheme? = nil,
        onPreferredSchemeChange: @escaping @MainActor (ColorScheme?) -> Void = { _ in }
    ) {
        self.preview = preview
        self.colorSchemeOverride = colorSchemeOverride
        self.onPreferredSchemeChange = onPreferredSchemeChange
    }

    package var body: some View {
        AnyView(preview.makeView())
            .onPreferenceChange(PreferredColorSchemeKey.self) { value in
                preferredScheme = value
                onPreferredSchemeChange(value)
            }
            .environment(
                \.colorScheme,
                colorSchemeOverride ?? preferredScheme ?? ambientScheme
            )
            .preferredColorScheme(nil)
    }
}
