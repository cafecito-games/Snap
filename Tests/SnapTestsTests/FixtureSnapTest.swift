import SnapTests

/// End-to-end coverage: running the test suite executes one generated XCTest
/// method per fixture preview, exercising discovery, rendering, and image
/// capture through the same path applications use.
final class FixtureSnapTest: SnapTest {

    override class func includedModules() -> [String]? {
        ["SnapTestsTests"]
    }
}
