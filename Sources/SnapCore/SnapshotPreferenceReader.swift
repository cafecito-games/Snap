import SwiftUI
import SnapModels

/// The per-preview preferences declared with the `SnapPreferences` modifiers,
/// read out of the running process after a render.
public struct SnapshotPreferenceSnapshot: Sendable {
    public static let empty = SnapshotPreferenceSnapshot()

    public var renderingMode: SnapshotRenderingMode?
    public var diffThreshold: Float?
    public var tags: [String: String]
    public var additionalContext: [String: SnapshotMetadataValue]

    init(
        renderingMode: SnapshotRenderingMode? = nil,
        diffThreshold: Float? = nil,
        tags: [String: String] = [:],
        additionalContext: [String: SnapshotMetadataValue] = [:]
    ) {
        self.renderingMode = renderingMode
        self.diffThreshold = diffThreshold
        self.tags = tags
        self.additionalContext = additionalContext
    }
}

/// Locates the `SnapPreferences` runtime through the Objective-C runtime.
///
/// `SnapPreferences` is linked into the app or framework that declares the
/// previews, not into the test bundle, so `SnapCore` must reach it
/// reflectively. When the library is absent every lookup safely produces
/// `nil` and rendering proceeds with default preferences.
@MainActor
enum SnapshotPreferenceReader {
    /// Wraps a view so preference modifiers write into the shared reader
    /// state. Wrapping also resets the state for the upcoming render.
    static var wrapWithPreferences: ((any View) -> any View)? {
        locate().map { reader in
            { view in
                reader.wrap(view)
            }
        }
    }

    static func readSnapshot() -> SnapshotPreferenceSnapshot {
        locate()?.readSnapshot() ?? .empty
    }

    private static func locate() -> PreferenceReaderProxy? {
        guard let readerClass = NSClassFromString("SnapPreferenceState") else {
            return nil
        }
        guard
            let shared = (readerClass as AnyObject)
                .perform(NSSelectorFromString("shared"))?
                .takeUnretainedValue()
        else {
            return nil
        }
        return PreferenceReaderProxy(sharedState: shared)
    }

    /// Reflects the `@objc(SnapPreferenceState)` singleton that
    /// `SnapPreferences` provides.
    private struct PreferenceReaderProxy {
        private let mirror: Mirror

        init(sharedState: AnyObject) {
            mirror = Mirror(reflecting: sharedState)
        }

        func wrap(_ view: any View) -> any View {

            guard let wrap = mirror.descendant("wrap") else {
                return view
            }
            guard let wrapClosure = wrap as? (any View) -> any View else {
                return view
            }
            return wrapClosure(view)
        }

        func readSnapshot() -> SnapshotPreferenceSnapshot {
            let renderingModeRawValue = mirror.descendant("renderingMode") as? SnapshotRenderingMode.RawValue
            return SnapshotPreferenceSnapshot(
                renderingMode: renderingModeRawValue.flatMap(SnapshotRenderingMode.init(rawValue:)),
                diffThreshold: mirror.descendant("diffThreshold") as? Float,
                tags: mirror.descendant("tags") as? [String: String] ?? [:],
                additionalContext: mirror.descendant("additionalContext") as? [String: SnapshotMetadataValue] ?? [:]
            )
        }
    }
}
