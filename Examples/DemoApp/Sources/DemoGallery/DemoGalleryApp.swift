import DemoKit
import SnapGallery
import SwiftUI

@main
struct DemoGalleryApp: App {
    init() {
        // Keep the preview-bearing module linked into the gallery process.
        _ = PlayerCard.self
    }

    var body: some Scene {
        WindowGroup {
            SnapGallery {
                Discover("DemoKit")
            }
        }
        .defaultSize(width: 1280, height: 800)
    }
}
