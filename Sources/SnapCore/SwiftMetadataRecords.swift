import Foundation

// Minimal declarations of the Swift runtime metadata records that the
// `__swift5_proto` section is built from. Field layouts follow the stable
// Swift ABI documented in apple/swift (include/swift/ABI/Metadata.h and
// include/swift/ABI/MetadataValues.h). Offsets between fields are relative
// 32-bit values, so the records can be read directly from mapped images.

/// Kinds of nominal type context descriptors.
/// See `ContextDescriptorKind` in MetadataValues.h.
enum ContextDescriptorKind: UInt8 {
    case module = 0
    case `extension` = 1
    case anonymous = 2
    case `protocol` = 3
    case opaqueType = 4
    case classType = 16
    case structType = 17
    case enumType = 18
}

/// How a protocol conformance refers to the conforming type.
/// See `TypeReferenceKind` in MetadataValues.h.
enum TypeReferenceKind: UInt32 {
    case directTypeDescriptor = 0
    case indirectTypeDescriptor = 1
    case directObjCClassName = 2
    case indirectObjCClass = 3
}

/// Flags packed into a context descriptor.
/// See `ContextDescriptorFlags` in MetadataValues.h.
struct ContextDescriptorFlags {
    private let rawFlags: UInt32

    init(rawFlags: UInt32) {
        self.rawFlags = rawFlags
    }

    var kind: ContextDescriptorKind? {
        ContextDescriptorKind(rawValue: UInt8(rawFlags & 0x1F))
    }
}

/// Flags packed into a protocol conformance descriptor.
/// See `ProtocolConformanceFlags` in MetadataValues.h.
struct ConformanceDescriptorFlags {
    private let rawFlags: UInt32

    init(rawFlags: UInt32) {
        self.rawFlags = rawFlags
    }

    private static let typeReferenceKindMask: UInt32 = 0x7 << 3

    var typeReferenceKind: TypeReferenceKind? {
        let rawKind = (rawFlags & Self.typeReferenceKindMask) >> 3
        return TypeReferenceKind(rawValue: rawKind)
    }
}

/// Common header of every context descriptor: flags, parent, name, and the
/// type metadata accessor. All pointer fields are relative offsets.
/// See `TargetContextDescriptor` in Metadata.h.
struct ContextDescriptorRecord {
    let flags: ContextDescriptorFlags
    let parent: Int32
    let name: Int32
    let accessFunction: Int32
}

/// A protocol conformance record from `__swift5_proto`.
/// See `TargetProtocolConformanceDescriptor` in Metadata.h.
struct ProtocolConformanceRecord {
    let protocolDescriptor: Int32
    let nominalTypeDescriptor: Int32
    let protocolWitnessTable: Int32
    let conformanceFlags: ConformanceDescriptorFlags

    init(rawWords: (Int32, Int32, Int32, UInt32)) {
        protocolDescriptor = rawWords.0
        nominalTypeDescriptor = rawWords.1
        protocolWitnessTable = rawWords.2
        conformanceFlags = ConformanceDescriptorFlags(rawFlags: rawWords.3)
    }
}

/// Header of a protocol descriptor, used to read the protocol's name.
/// See `TargetProtocolDescriptor` in Metadata.h.
struct ProtocolDescriptorRecord {
    let flags: UInt32
    let parent: Int32
    let name: Int32
}
