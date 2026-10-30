import SnapTests
import UIKitExampleFixtures

/// Verifies that Snap enumerates one XCTest per linked preview inside an iOS
/// Simulator test bundle, just as it does on macOS.
final class UIKitExampleDynamicTests: SnapTest {
    override class func includedModules() -> [String]? {
        [
            String(
                String(reflecting: UIKitExampleMarker.self)
                    .split(separator: ".", maxSplits: 1)
                    .first ?? ""
            ),
        ]
    }
}
