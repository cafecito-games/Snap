import SnapTests
import UIKitSpikeFixtures

/// The spike's final gate: Snap must enumerate one XCTest per linked preview
/// inside an iOS Simulator test bundle, just as it does on macOS.
final class UIKitSpikeDynamicTests: SnapTest {
    override class func includedModules() -> [String]? {
        [
            String(
                String(reflecting: UIKitSpikeMarker.self)
                    .split(separator: ".", maxSplits: 1)
                    .first ?? ""
            ),
        ]
    }
}
