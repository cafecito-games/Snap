import Foundation
import XCTest
import SnapCore
import SnapTestSupport

/// One dynamically generated test case awaiting execution.
@MainActor
public struct PendingPreviewCase {
    public let container: PreviewContainer
    public let preview: RenderablePreview
    public let ordinal: Int
}

/// Base class that turns discovered previews into real XCTest methods at
/// enumeration time.
///
/// XCTest discovers tests through `+[XCTestCase testInvocations]`, which is
/// not overridable from Swift. `SnapTestSupport` hooks that class method and
/// routes it here for Snap subclasses; everything else proceeds normally.
@objc(SnapDynamicTestCase)
open class SnapDynamicTestCase: XCTestCase {

    /// A stable identifier for the concrete test class.
    private static var className: String {
        NSStringFromClass(self)
    }

    /// Builds the invocations XCTest will run. Called once per subclass, on
    /// the main thread during test enumeration.
    @objc
    open class func snapBuildTestInvocations() -> [AnyObject] {
        guard shouldGenerateTests() else {
            return []
        }
        let className = NSStringFromClass(self)
        // The invocations array holds non-Sendable NSInvocation objects; the
        // unchecked box carries them across the isolation boundary safely.
        let invocations = MainActor.assumeIsolated {
            UncheckedSender(
                value: DynamicTestRegistry.shared.testInvocations(className: className)
            )
        }
        return invocations.value
    }

    /// Whether this class should generate dynamic preview tests. Subclasses
    /// in the SnapTests package itself never do.
    open class func shouldGenerateTests() -> Bool {
        let className = NSStringFromClass(self)
        return className != "SnapDynamicTestCase" && !className.hasPrefix("SnapTests.")
    }

    /// Discovers the preview containers this class should render.
    @MainActor
    open class func discoverPreviewContainers() -> [PreviewContainer] {
        []
    }

    /// Runs a single generated case. Subclasses implement rendering here.
    @MainActor
    open func run(pendingCase: PendingPreviewCase) {
        // Implemented by SnapTest and its subclasses.
    }
}

/// Owns the mapping from generated selectors to pending cases.
@MainActor
final class DynamicTestRegistry {

    static let shared = DynamicTestRegistry()

    private var pendingCases: [String: [String: PendingPreviewCase]] = [:]
    private var invocationsByClassName: [String: [AnyObject]] = [:]

    func testInvocations(className: String) -> [AnyObject] {
        let className = className
        if let cached = invocationsByClassName[className] {
            return cached
        }
        guard let testClass = NSClassFromString(className) as? SnapDynamicTestCase.Type else {
            return []
        }

        var casesBySelector: [String: PendingPreviewCase] = [:]
        var selectorNames: [String] = []
        var ordinal = 0
        for container in testClass.discoverPreviewContainers() {
            for preview in container.previews {
                let selectorName = Self.selectorName(
                    container: container,
                    preview: preview,
                    ordinal: ordinal
                )
                selectorNames.append(selectorName)
                casesBySelector[selectorName] = PendingPreviewCase(
                    container: container,
                    preview: preview,
                    ordinal: ordinal
                )
                ordinal += 1
            }
        }

        pendingCases[className] = casesBySelector
        let invocations: [AnyObject] = selectorNames.map { selectorName in
            let selector = NSSelectorFromString(selectorName)
            let implementation = unsafeBitCast(
                Self.dynamicTestMethod,
                to: UnsafeRawPointer.self
            )
            let added = class_addMethod(
                testClass,
                selector,
                OpaquePointer(implementation),
                "v@:"
            )
            if !added {
                print("Snap: could not register test method \(selectorName)")
            }
            return SnapTestInvocationFactory.invocation(for: selector)
        }
        invocationsByClassName[className] = invocations
        return invocations
    }

    func pendingCase(className: String, selectorName: String) -> PendingPreviewCase? {
        pendingCases[className]?[selectorName]
    }

    private static func selectorName(
        container: PreviewContainer,
        preview: RenderablePreview,
        ordinal: Int
    ) -> String {
        let baseName = preview.displayName ?? container.displayName
        return "test \(baseName.sanitizedForSelector()) \(ordinal)"
    }

    /// Reads the pending case for the receiver and runs it.
    private static let dynamicTestMethod: @convention(c) (AnyObject, Selector) -> Void =
        { receiver, command in
            let selectorName = NSStringFromSelector(command)
            let className = NSStringFromClass(type(of: receiver))
            // XCTest invokes generated test methods on the main thread; the
            // unchecked box carries the receiver across the isolation check.
            let receiverBox = UncheckedSender(value: receiver)
            MainActor.assumeIsolated {
                guard
                    let testCase = receiverBox.value as? SnapDynamicTestCase,
                    let pendingCase = DynamicTestRegistry.shared.pendingCase(
                        className: className,
                        selectorName: selectorName
                    )
                else {
                    if let testCase = receiverBox.value as? SnapDynamicTestCase {
                        testCase.reportMissingCase(selectorName: selectorName)
                    }
                    return
                }
                testCase.run(pendingCase: pendingCase)
            }
        }
}

/// Wraps a value that is known to cross actors safely, such as the main-thread
/// test-case receiver.
private final class UncheckedSender<T>: @unchecked Sendable {
    let value: T

    init(value: T) {
        self.value = value
    }
}

extension SnapDynamicTestCase {
    @MainActor
    fileprivate func reportMissingCase(selectorName: String) {
        XCTFail("Snap: no preview is registered for test method \(selectorName).")
    }
}

extension String {
    /// Keeps characters that are safe inside an Objective-C selector and are
    /// still readable in Xcode's test navigator.
    func sanitizedForSelector() -> String {
        String(map { character in
            character.isLetter || character.isNumber || character == " " || character == "-" || character == "_"
                ? character
                : " "
        })
    }
}
