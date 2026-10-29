import Foundation

/// Which previews a test run should render. All fields are regex patterns for
/// names and exact identifiers for modules; `nil` means "no restriction".
@frozen
public struct PreviewSelection: Sendable {
    public var includedPreviewNames: [String]?
    public var excludedPreviewNames: [String]?
    public var includedModules: [String]?
    public var excludedModules: [String]?

    public init(
        includedPreviewNames: [String]? = nil,
        excludedPreviewNames: [String]? = nil,
        includedModules: [String]? = nil,
        excludedModules: [String]? = nil
    ) {
        self.includedPreviewNames = includedPreviewNames
        self.excludedPreviewNames = excludedPreviewNames
        self.includedModules = includedModules
        self.excludedModules = excludedModules
    }

    func includesModule(named moduleName: String) -> Bool {
        if let excludedModules, excludedModules.contains(moduleName) {
            return false
        }
        guard let includedModules else {
            return true
        }
        return includedModules.contains(moduleName)
    }

    func includesPreview(named name: String) -> Bool {
        if let excludedPreviewNames, matchesAnyPattern(name, patterns: excludedPreviewNames, sense: .exclusion) {
            return false
        }
        guard let includedPreviewNames else {
            return true
        }
        return matchesAnyPattern(name, patterns: includedPreviewNames, sense: .inclusion)
    }

    private enum MatchSense {
        case inclusion
        case exclusion
    }

    private func matchesAnyPattern(_ name: String, patterns: [String], sense: MatchSense) -> Bool {
        for pattern in patterns {
            do {
                if name.firstMatch(of: try Regex(pattern)) != nil {
                    return true
                }
            } catch {
                print("Snap: ignoring invalid preview filter pattern '\(pattern)': \(error)")
                if sense == .exclusion {
                    // An unparsable exclusion cannot safely exclude anything;
                    // keep scanning the remaining patterns.
                    continue
                }
            }
        }
        return false
    }
}
