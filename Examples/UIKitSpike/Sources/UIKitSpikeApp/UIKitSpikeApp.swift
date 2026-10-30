import SnapCore
import SwiftUI
import UIKitSpikeFixtures

@main
struct UIKitSpikeApp: App {
    var body: some Scene {
        WindowGroup {
            UIKitSpikeStatusView()
        }
    }
}
private struct UIKitSpikeStatusView: View {
    @State private var status = "Discovering previews…"

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Snap UIKit Spike",
                systemImage: "rectangle.stack",
                description: Text(status)
            )
            .navigationTitle("Snap")
        }
        .task {
            let moduleName = String(
                String(reflecting: UIKitSpikeMarker.self)
                    .split(separator: ".", maxSplits: 1)
                    .first ?? ""
            )
            let containers = PreviewDiscovery.discoverContainers(
                selection: PreviewSelection(includedModules: [moduleName])
            )
            let previewCount = containers.reduce(0) { $0 + $1.previews.count }
            status = "Discovered \(previewCount) previews from \(moduleName)."
        }
    }
}
