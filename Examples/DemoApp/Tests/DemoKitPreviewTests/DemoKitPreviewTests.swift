import SnapTests
@testable import DemoKit

/// The entire snapshot test suite for the demo module: one class, no test
/// methods. Snap discovers every `#Preview` in DemoKit at runtime.
final class DemoKitPreviewTests: SnapTest {

    override class func includedModules() -> [String]? {
        ["DemoKit"]
    }
}
