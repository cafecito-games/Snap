import SwiftUI
import SnapPreferences

// Fixtures for exercising Snap's discovery and rendering. The `#Preview`
// macros expand into `PreviewRegistry` conformances and the provider below
// contributes `PreviewProvider` conformances, both of which the scanner
// should find inside this test bundle.

#Preview("Fixture With Preferences") {
    Text("Tagged Fixture")
        .padding()
        .snapTags(["area": "fixtures"])
        .snapDiffThreshold(0.1)
        .snapAdditionalContext(["fixture": "tagged"])
}


#Preview("Fixture Greeting") {
    VStack(spacing: 12) {
        Image(systemName: "hand.wave")
            .font(.system(size: 40))
        Text("Hello, Snap")
            .font(.title2)
            .padding()
    }
    .frame(width: 240, height: 160)
}

#Preview("Fixture Greeting Dark") {
    VStack(spacing: 12) {
        Image(systemName: "hand.wave")
            .font(.system(size: 40))
        Text("Hello, Snap")
            .font(.title2)
            .padding()
    }
    .frame(width: 240, height: 160)
    .preferredColorScheme(.dark)
}

#Preview("Fixture Layer Rendering") {
    Text("Layer Fixture")
        .padding()
        .background(.ultraThinMaterial)
        .snapRenderingMode(.layer)
}

#Preview {
    Text("Unnamed Fixture")
        .padding()
}

struct FixtureProviderPreviews: PreviewProvider {
    static var previews: some View {
        Text("Provider First")
            .previewDisplayName("Provider First")
        Text("Provider Second")
            .previewDisplayName("Provider Second")
    }
}
