import DemoKit
import SnapGallery
import SwiftUI

@main
struct DemoGalleryApp: App {
    var body: some Scene {
        WindowGroup {
            SnapGallery {
                Discover(from: PlayerCard.self)
            }
        }
        .defaultSize(width: 1280, height: 800)
    }
}
