import SnapPreferences
import SwiftUI
import UIKit

/// A public marker that keeps this fixture module linked into the spike host.
public enum UIKitSpikeMarker {}

public struct UIKitSpikeCard: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("UIKit renderer")
                .font(.headline)
            Text("Discovered from a compiled #Preview")
                .foregroundStyle(.secondary)
            UIKitSpikeLabel(text: "UIViewRepresentable")
                .frame(height: 32)
        }
        .padding(20)
        .frame(width: 320, alignment: .leading)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
public struct UIKitSpikeLabel: UIViewRepresentable {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = .systemIndigo
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        return label
    }

    public func updateUIView(_ label: UILabel, context: Context) {
        label.text = text
    }
}

public struct UIKitSpikeProviderPreviews: PreviewProvider {
    public static var previews: some View {
        UIKitSpikeCard()
            .previewDisplayName("UIKit Provider")
    }
}

#Preview("UIKit Spike Card", traits: .sizeThatFitsLayout) {
    UIKitSpikeCard()
        .snapTags(["platform": "uikit", "kind": "swiftui"])
}

#Preview("UIKit Representable", traits: .fixedLayout(width: 280, height: 80)) {
    UIKitSpikeLabel(text: "Native UIKit content")
        .padding()
}

#Preview("UIKit Layer", traits: .fixedLayout(width: 280, height: 80)) {
    Text("Layer-backed capture")
        .padding()
        .background(.ultraThinMaterial)
        .snapRenderingMode(.layer)
}
