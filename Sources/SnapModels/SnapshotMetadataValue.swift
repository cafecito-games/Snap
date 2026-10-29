import Foundation

/// A JSON-safe metadata value used in exported snapshot sidecars.
///
/// Only strings, numbers, booleans, and nested dictionaries of those types can
/// be encoded, which keeps the sidecar schema stable for downstream consumers.
public enum SnapshotMetadataValue: Sendable, Equatable, Encodable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: SnapshotMetadataValue])

    /// Converts an untyped dictionary into metadata values.
    ///
    /// - Precondition: Every value must be a string, boolean, finite number,
    ///   or a nested dictionary of supported values.
    public static func dictionary(from values: [String: Any]) -> [String: SnapshotMetadataValue] {
        values.mapValues { SnapshotMetadataValue($0) }
    }

    /// Creates a metadata value from an untyped input.
    ///
    /// - Precondition: The value must be a string, boolean, finite number,
    ///   or a nested dictionary of supported values.
    public init(_ value: Any) {
        switch value {
        case let value as SnapshotMetadataValue:
            self = value
        case let value as String:
            self = .string(value)
        case let value as Bool:
            self = .bool(value)
        case let value as Int:
            self = .number(Double(value))
        case let value as Int8:
            self = .number(Double(value))
        case let value as Int16:
            self = .number(Double(value))
        case let value as Int32:
            self = .number(Double(value))
        case let value as Int64:
            self = .number(Double(value))
        case let value as UInt:
            self = .number(Double(value))
        case let value as UInt8:
            self = .number(Double(value))
        case let value as UInt16:
            self = .number(Double(value))
        case let value as UInt32:
            self = .number(Double(value))
        case let value as UInt64:
            self = .number(Double(value))
        case let value as Double:
            self = .number(value)
        case let value as Float:
            self = .number(Double(value))
        case let value as CGFloat:
            self = .number(Double(value))
        case let value as NSNumber:
            if CFGetTypeID(value as CFTypeRef) == CFBooleanGetTypeID() {
                self = .bool(value.boolValue)
            } else {
                self = .number(value.doubleValue)
            }
        case let value as [String: Any]:
            self = .object(Self.dictionary(from: value))
        default:
            preconditionFailure("Unsupported snapshot metadata value type: \(type(of: value))")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .bool(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        }
    }
}
