import XCTest
import SnapCore

/// A `SnapTest` that lays every preview out without capturing images.
///
/// Use this to verify cheaply that every preview renders without crashing —
/// for example to catch a missing `@EnvironmentObject` — before paying for
/// pixel capture in a full `SnapTest` run.
open class SnapLayoutTest: SnapTest {

    override open class func capturesImages() -> Bool {
        false
    }
}
