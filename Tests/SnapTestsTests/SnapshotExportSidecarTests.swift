import XCTest
import SnapModels
@testable import SnapTests

final class SnapshotExportSidecarTests: XCTestCase {

    func testSidecarEncodesSentryCompatibleSchema() throws {
        let sidecar = SnapshotExportCoordinator.Sidecar(
            .init(
                imageFileName: "Module_Fixtures.swift_Greeting.png",
                testName: "-[PreviewTests test Greeting 0]",
                containerTypeName: "Module.__macro__Preview",
                containerDisplayName: "fixtures",
                previewDisplayName: "Greeting",
                previewIndex: 0,
                preferredDisplayName: "Greeting",
                group: "Module/Fixtures.swift",
                line: 12,
                orientation: "portrait",
                colorScheme: "dark",
                diffThreshold: 0.05,
                tags: ["screen": "home"],
                additionalContext: [
                    "fixture": .string("loaded"),
                    "test_name": .string("custom"),
                ]
            )
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = [.sortedKeys]
        let json = try JSONSerialization.jsonObject(
            with: encoder.encode(sidecar)
        ) as! [String: Any]

        XCTAssertEqual(json["display_name"] as? String, "Greeting")
        XCTAssertEqual(json["group"] as? String, "Module/Fixtures.swift")
        XCTAssertEqual(json["diff_threshold"] as? Double, 0.05)
        XCTAssertEqual(json["tags"] as? [String: String], ["screen": "home"])

        let context = json["context"] as! [String: Any]
        XCTAssertEqual(context["test_name"] as? String, "custom", "custom context overrides generated keys")
        XCTAssertEqual(context["fixture"] as? String, "loaded")

        let preview = context["preview"] as! [String: Any]
        XCTAssertEqual(preview["index"] as? Int, 0)
        XCTAssertEqual(preview["display_name"] as? String, "Greeting")
        XCTAssertEqual(preview["container_type_name"] as? String, "Module.__macro__Preview")
        XCTAssertEqual(preview["container_display_name"] as? String, "fixtures")
        XCTAssertEqual(preview["preferred_color_scheme"] as? String, "dark")
        XCTAssertEqual(preview["orientation"] as? String, "portrait")
        XCTAssertEqual(preview["line"] as? Int, 12)
    }

    func testSidecarOmitsOptionalEmptyFields() throws {
        let sidecar = SnapshotExportCoordinator.Sidecar(
            .init(
                imageFileName: "snapshot.png",
                testName: "t",
                containerTypeName: "M.T",
                containerDisplayName: "t",
                previewDisplayName: nil,
                previewIndex: 1,
                preferredDisplayName: "1",
                group: "t",
                line: nil,
                orientation: "portrait",
                colorScheme: nil,
                diffThreshold: nil,
                tags: [:],
                additionalContext: [:]
            )
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let json = try JSONSerialization.jsonObject(
            with: encoder.encode(sidecar)
        ) as! [String: Any]

        XCTAssertNil(json["diff_threshold"])
        XCTAssertNil(json["tags"])
        let preview = json["context"] as! [String: Any]
        let previewContext = preview["preview"] as! [String: Any]
        XCTAssertNil(previewContext["display_name"])
        XCTAssertNil(previewContext["preferred_color_scheme"])
        XCTAssertNil(previewContext["line"])
    }
}
