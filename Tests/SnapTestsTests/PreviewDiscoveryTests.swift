import XCTest
@testable import SnapCore
@testable import SnapTests

@MainActor
final class PreviewDiscoveryTests: XCTestCase {

    func testDiscoversMacroPreviewsWithFileAndDisplayName() {
        let containers = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(includedModules: [moduleName])
        )
        let macroContainers = containers.filter { $0.fileID != nil }
        XCTAssertTrue(
            macroContainers.contains {
                $0.previews.first?.displayName == "Fixture Greeting"
            },
            "Expected to find the 'Fixture Greeting' macro preview. Found: \(macroContainers.map(\.typeName))"
        )
    }

    func testDiscoversProviderPreviewsWithOneEntryPerChild() {
        let containers = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(includedModules: [moduleName])
        )
        let providerContainer = containers.first {
            $0.typeName.hasSuffix("FixtureProviderPreviews")
        }
        XCTAssertNotNil(
            providerContainer,
            "Expected to find FixtureProviderPreviews. Found: \(containers.map(\.typeName))"
        )
        XCTAssertEqual(
            providerContainer?.previews.map(\.displayName),
            ["Provider First", "Provider Second"]
        )
    }

    func testModuleNameFilterExcludesOtherModules() {
        let containers = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(includedModules: ["DefinitelyNotAModule"])
        )
        XCTAssertTrue(containers.isEmpty)
    }

    func testNameFilterMatchesFileIDAndDisplayName() {
        let containers = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(
                includedPreviewNames: ["Fixtures.swift:Fixture Greeting Dark"]
            )
        )
        XCTAssertEqual(containers.count, 1)
        XCTAssertEqual(containers.first?.previews.first?.displayName, "Fixture Greeting Dark")
    }

    func testExcludedNameFilterDropsMatchingPreviews() {
        let all = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(includedModules: [moduleName])
        )
        let withoutGreeting = PreviewDiscovery.discoverContainers(
            selection: PreviewSelection(
                excludedPreviewNames: ["Fixture Greeting"],
                includedModules: [moduleName]
            )
        )
        XCTAssertGreaterThan(all.count, withoutGreeting.count)
        XCTAssertTrue(
            withoutGreeting.allSatisfy { container in
                container.previews.allSatisfy { $0.displayName != "Fixture Greeting" }
            }
        )
    }

    var moduleName: String {
        // `String(reflecting:)` on a metatype yields the fully qualified name,
        // for example "SnapTestsTests.PreviewDiscoveryTests".
        String(String(reflecting: Self.self).split(separator: ".").first ?? "")
    }
}
