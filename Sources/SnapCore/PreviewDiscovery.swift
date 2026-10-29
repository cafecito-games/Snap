import Foundation
import SwiftUI

/// Discovers preview containers in every loaded image and applies the given
/// selection filters.
@MainActor
public enum PreviewDiscovery {
    /// Scans the process for preview declarations and materializes those that
    /// pass the filters. Materializing a preview type runs its view-building
    /// declarations, so discovery happens on the main actor.
    public static func discoverContainers(selection: PreviewSelection) -> [PreviewContainer] {
        PreviewConformanceScanner.scan().compactMap { conformance in
            guard selection.includesModule(named: moduleName(of: conformance.typeName)) else {
                return nil
            }
            guard let container = materialize(conformance: conformance) else {
                return nil
            }
            guard selection.includesPreview(named: container.filterName) else {
                return nil
            }
            return container
        }
    }

    private static func moduleName(of typeName: String) -> String {
        String(typeName.split(separator: ".", maxSplits: 1).first ?? "")
    }

    /// Opens the existential so the provider's concrete `previews` type can
    /// flow through the variadic view tree.
    private static func makeProviderContainer<P: PreviewProvider>(
        typeName: String,
        provider: P.Type
    ) -> PreviewContainer {
        PreviewProviderBridging.makeContainer(typeName: typeName, provider: provider)
    }

    private static func materialize(conformance: PreviewConformance) -> PreviewContainer? {
        let metadata = unsafeBitCast(
            conformance.metadataAccessor(),
            to: Any.Type.self
        )
        switch conformance.protocolName {
        case "PreviewProvider":
            guard let provider = metadata as? any PreviewProvider.Type else {
                return nil
            }
            return makeProviderContainer(
                typeName: conformance.typeName,
                provider: provider
            )
        case "PreviewRegistry":
            guard let registry = metadata as? any PreviewRegistry.Type else {
                return nil
            }
            do {
                return try PreviewRegistryBridging.makeContainer(
                    typeName: conformance.typeName,
                    registry: registry
                )
            } catch {
                print("Snap: skipping preview \(conformance.typeName): \(error)")
                return nil
            }
        default:
            return nil
        }
    }
}
