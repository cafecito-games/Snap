import SwiftUI
import SnapModels

/// Collects the snapshot preference modifiers applied to the preview that is
/// currently being rendered.
///
/// `SnapCore` locates this class through the Objective-C runtime and reads it
/// reflectively, which keeps `SnapPreferences` linkable into app targets
/// without a compile-time dependency on `SnapCore`.
@MainActor
@objc(SnapPreferenceState)
final class PreferenceState: NSObject {

    @objc static let shared = PreferenceState()

    /// Wraps the rendered view with preference collectors. Calling this also
    /// resets all collected state for the upcoming render.
    let wrap: (any View) -> any View = { view in
        PreferenceState.shared.reset()
        return view
            .onPreferenceChange(SnapshotDiffThresholdKey.self) { value in
                PreferenceState.shared.diffThreshold = value
            }
            .onPreferenceChange(SnapshotRenderingModeKey.self) { value in
                PreferenceState.shared.renderingMode = value
            }
            .onPreferenceChange(SnapshotTagsKey.self) { value in
                PreferenceState.shared.tags = value
            }
            .onPreferenceChange(SnapshotAdditionalContextKey.self) { value in
                PreferenceState.shared.additionalContext = value
            }
    }

    var renderingMode: SnapshotRenderingMode.RawValue?
    var diffThreshold: Float?
    var tags: [String: String] = [:]
    var additionalContext: [String: SnapshotMetadataValue] = [:]

    private override init() {
        super.init()
    }

    private func reset() {
        renderingMode = nil
        diffThreshold = nil
        tags = [:]
        additionalContext = [:]
    }
}

/// Gives package targets that read preferences reflectively a direct symbol
/// reference so the collector is retained by the linker in application builds.
@MainActor
package enum SnapPreferencesRuntime {
    package static func ensureLoaded() {
        _ = PreferenceState.shared
    }

    package static func wrap(_ view: any View) -> any View {
        PreferenceState.shared.wrap(view)
    }

    package static var renderingMode: SnapshotRenderingMode.RawValue? {
        PreferenceState.shared.renderingMode
    }

    package static var diffThreshold: Float? {
        PreferenceState.shared.diffThreshold
    }

    package static var tags: [String: String] {
        PreferenceState.shared.tags
    }

    package static var additionalContext: [String: SnapshotMetadataValue] {
        PreferenceState.shared.additionalContext
    }
}

// MARK: - Preference keys

struct SnapshotDiffThresholdKey: PreferenceKey {
    static let defaultValue: Float? = nil

    static func reduce(value: inout Float?, nextValue: () -> Float?) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct SnapshotRenderingModeKey: PreferenceKey {
    static let defaultValue: SnapshotRenderingMode.RawValue? = nil

    static func reduce(value: inout SnapshotRenderingMode.RawValue?, nextValue: () -> SnapshotRenderingMode.RawValue?) {
        if let next = nextValue() {
            value = next
        }
    }
}

struct SnapshotTagsKey: PreferenceKey {
    static let defaultValue: [String: String] = [:]

    static func reduce(value: inout [String: String], nextValue: () -> [String: String]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

struct SnapshotAdditionalContextKey: PreferenceKey {
    static let defaultValue: [String: SnapshotMetadataValue] = [:]

    static func reduce(
        value: inout [String: SnapshotMetadataValue],
        nextValue: () -> [String: SnapshotMetadataValue]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
