import XCTest
@testable import SnapTests

final class SnapshotFileNameTests: XCTestCase {

    func testSanitizeCollapsesDisallowedCharacters() {
        XCTAssertEqual(
            SnapshotFileName.sanitize("EditorWorkspace/PreviewCatalog.swift:Project Processing/Regular"),
            "EditorWorkspace_PreviewCatalog.swift_Project_Processing_Regular"
        )
    }

    func testSanitizeKeepsLettersNumbersAndSeparators() {
        XCTAssertEqual(SnapshotFileName.sanitize("a.b-c_d 1"), "a.b-c_d_1")
    }

    func testSanitizeTrimsLeadingAndTrailingSeparators() {
        XCTAssertEqual(SnapshotFileName.sanitize("///name///"), "name")
    }

    func testSanitizeFallsBackForFullyInvalidInput() {
        XCTAssertEqual(SnapshotFileName.sanitize("///"), "snapshot")
    }

    func testImageFileNameAppendsPNGExtension() {
        XCTAssertEqual(
            SnapshotFileName.imageFileName(from: "hello world"),
            "hello_world.png"
        )
    }

    @MainActor
    func testBaseFileNameUsesFileIDPrefixForMacroPreviews() {
        let name = SnapshotFileName.baseFileName(
            containerDisplayName: "Ignored",
            fileID: "Module/Fixtures.swift",
            line: 3,
            previewDisplayName: "Fixture Greeting",
            previewIndex: 0,
            duplicateOrdinal: nil
        )
        XCTAssertEqual(name, "Module/Fixtures.swift_Fixture Greeting")
    }

    @MainActor
    func testBaseFileNameFallsBackToLineForUnnamedMacroPreviews() {
        let name = SnapshotFileName.baseFileName(
            containerDisplayName: "Ignored",
            fileID: "Module/Fixtures.swift",
            line: 21,
            previewDisplayName: nil,
            previewIndex: 0,
            duplicateOrdinal: nil
        )
        XCTAssertEqual(name, "Module/Fixtures.swift_line-21")
    }

    @MainActor
    func testBaseFileNameUsesIndexForUnnamedProviderChildren() {
        let name = SnapshotFileName.baseFileName(
            containerDisplayName: "Fixture Provider",
            fileID: nil,
            line: nil,
            previewDisplayName: nil,
            previewIndex: 2,
            duplicateOrdinal: nil
        )
        XCTAssertEqual(name, "Fixture Provider_2")
    }
}
