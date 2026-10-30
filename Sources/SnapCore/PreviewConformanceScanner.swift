import Foundation
import MachO

/// A protocol conformance to a preview protocol, located in a loaded image.
struct PreviewConformance {
    /// Fully-qualified name of the conforming type, for example
    /// `"MyModule.MyView_Previews"`.
    let typeName: String

    /// Either `"PreviewProvider"` or `"PreviewRegistry"`.
    let protocolName: String

    /// The type's metadata accessor. Calling it yields the type metadata
    /// pointer, which can be reinterpreted as `Any.Type`.
    let metadataAccessor: @convention(c) () -> UInt64
}

/// Scans the `__swift5_proto` sections of all non-system images loaded in the
/// current process for conformances to SwiftUI's `PreviewProvider` and
/// DeveloperToolsSupport's `PreviewRegistry` (the protocol the `#Preview`
/// macro expands to).
enum PreviewConformanceScanner {
    static let previewProtocolNames: Set<String> = ["PreviewProvider", "PreviewRegistry"]

    /// Scans all eligible loaded images and reuses the result until dyld adds
    /// or removes an image from the process.
    static func scan() -> [PreviewConformance] {
        let imageCount = _dyld_image_count()
        if let cached = cachedConformances, cachedImageCount == imageCount {
            return cached
        }
        let conformances = scanEachLoadedImage()
        cachedConformances = conformances
        cachedImageCount = _dyld_image_count()
        return conformances
    }

    // Read and updated from the main thread during discovery. The image count
    // prevents a gallery refresh from returning a catalog cached before a
    // newly loaded preview module became available.
    nonisolated(unsafe) private static var cachedConformances: [PreviewConformance]?
    nonisolated(unsafe) private static var cachedImageCount: UInt32?

    private static func scanEachLoadedImage() -> [PreviewConformance] {
        var conformances: [PreviewConformance] = []
        let imageCount = _dyld_image_count()
        for imageIndex in 0..<imageCount {
            guard let header = _dyld_get_image_header(imageIndex) else { continue }
            guard isCandidateImage(header: header, imageIndex: imageIndex) else {
                continue
            }
            conformances.append(contentsOf: scanImage(header: header))
        }
        return conformances
    }

    /// System images ship in the dyld cache and can never declare app
    /// previews; test support runtimes are likewise irrelevant.
    private static func isCandidateImage(header: UnsafePointer<mach_header>, imageIndex: UInt32) -> Bool {
        let flags: UInt32 = header.pointee.flags
        if flags & UInt32(MH_DYLIB_IN_CACHE) != 0 {
            return false
        }
        let imageName = String(cString: _dyld_get_image_name(imageIndex))
        return !isSystemImagePath(imageName)
    }


    private static func isSystemImagePath(_ path: String) -> Bool {
        path.hasPrefix("/usr/lib/")
            || path.hasPrefix("/System/Library/")
            || path.contains(".simruntime")
            || path.contains(".platform/")
    }

    private static func scanImage(header: UnsafePointer<mach_header>) -> [PreviewConformance] {
        // All supported destinations are 64-bit, so the section lookup uses
        // the 64-bit header view of the same memory.
        let header64 = UnsafeRawPointer(header).assumingMemoryBound(to: mach_header_64.self)
        var sectionSize: UInt = 0
        guard
            let sectionBytes = getsectiondata(
                header64,
                "__TEXT",
                "__swift5_proto",
                &sectionSize
            )
        else {
            return []
        }
        let sectionStart = UnsafeRawPointer(sectionBytes).assumingMemoryBound(to: Int32.self)

        var conformances: [PreviewConformance] = []
        let recordCount = Int(sectionSize) / MemoryLayout<Int32>.size
        var cursor = sectionStart
        for _ in 0..<recordCount {
            let recordAddress = UnsafeRawPointer(cursor).advanced(by: Int(cursor.pointee))
            if let conformance = parseConformance(at: recordAddress) {
                conformances.append(conformance)
            }
            cursor = cursor.successor()
        }
        return conformances
    }

    /// Word offsets inside a protocol conformance record.
    private static let protocolDescriptorFieldOffset = 0
    private static let nominalTypeDescriptorFieldOffset = MemoryLayout<Int32>.size

    private static func parseConformance(at address: UnsafeRawPointer) -> PreviewConformance? {
        let record = loadProtocolConformanceRecord(at: address)
        guard record.conformanceFlags.typeReferenceKind == .directTypeDescriptor else {
            return nil
        }

        guard let protocolName = resolveProtocolName(record: record, address: address) else {
            return nil
        }
        guard previewProtocolNames.contains(protocolName) else {
            return nil
        }

        let typeDescriptor = address
            .advanced(by: Self.nominalTypeDescriptorFieldOffset)
            .advanced(by: Int(record.nominalTypeDescriptor))
            .assumingMemoryBound(to: ContextDescriptorRecord.self)

        guard
            let typeName = conformanceTypeName(descriptor: typeDescriptor),
            let accessor = metadataAccessor(descriptor: typeDescriptor)
        else {
            return nil
        }

        return PreviewConformance(
            typeName: typeName,
            protocolName: protocolName,
            metadataAccessor: accessor
        )
    }

    private static func loadProtocolConformanceRecord(at address: UnsafeRawPointer) -> ProtocolConformanceRecord {
        let words = address.assumingMemoryBound(to: Int32.self)
        let rawFlags = UnsafeRawPointer(words)
            .advanced(by: MemoryLayout<Int32>.size * 3)
            .assumingMemoryBound(to: UInt32.self)
            .pointee
        return ProtocolConformanceRecord(
            rawWords: (words[0], words[1], words[2], rawFlags)
        )
    }

    /// Resolves the name of the conformed protocol. The protocol descriptor
    /// is referenced indirectly through an absolute-pointer slot, which is
    /// zero when the protocol is unavailable at runtime.
    private static func resolveProtocolName(
        record: ProtocolConformanceRecord,
        address: UnsafeRawPointer
    ) -> String? {
        // swiftlint:disable:next unused_label
        // An odd offset marks an indirect reference through a symbol pointer.
        guard record.protocolDescriptor % 2 == 1 else {
            return nil
        }
        let descriptorOffset = Int(record.protocolDescriptor & ~1)
        let jumpSlot = address
            .advanced(by: Self.protocolDescriptorFieldOffset)
            .advanced(by: descriptorOffset)
        let protocolDescriptorAddress = UInt(jumpSlot.load(as: UInt64.self))

        guard protocolDescriptorAddress != 0 else {
            return nil
        }

        let descriptor = UnsafeRawPointer(bitPattern: protocolDescriptorAddress)!
            .assumingMemoryBound(to: ProtocolDescriptorRecord.self)
        let nameFieldOffset = MemoryLayout<ProtocolDescriptorRecord>.offset(of: \.name)!
        let nameAddress = UnsafeRawPointer(descriptor)
            .advanced(by: nameFieldOffset)
            .advanced(by: Int(descriptor.pointee.name))
        return String(cString: nameAddress.assumingMemoryBound(to: CChar.self))
    }

    /// The conforming type's name, or `nil` when the descriptor does not
    /// describe a nominal type.
    private static func conformanceTypeName(
        descriptor: UnsafePointer<ContextDescriptorRecord>
    ) -> String? {
        switch descriptor.pointee.flags.kind {
        case .classType, .structType, .enumType:
            return descriptorChainName(descriptor: descriptor)
        default:
            return nil
        }
    }

    /// Reconstructs the dotted type name by walking parent descriptors. The
    /// walk ends at the module descriptor, whose own name becomes the first
    /// component; indirect parent references (extensions, anonymous contexts)
    /// stop the walk early.
    private static func descriptorChainName(
        descriptor: UnsafePointer<ContextDescriptorRecord>
    ) -> String? {
        let nameFieldOffset = MemoryLayout<ContextDescriptorRecord>.offset(of: \.name)!
        let nameAddress = UnsafeRawPointer(descriptor)
            .advanced(by: nameFieldOffset)
            .advanced(by: Int(descriptor.pointee.name))
        let ownName = String(cString: nameAddress.assumingMemoryBound(to: CChar.self))

        let parentOffset = Int(descriptor.pointee.parent)
        guard parentOffset != 0 else {
            return ownName
        }
        // An odd parent offset is an indirect reference we do not chase.
        guard abs(parentOffset) % 2 == 0 else {
            return nil
        }
        let parentAddress = UnsafeRawPointer(descriptor)
            .advanced(by: MemoryLayout<ContextDescriptorRecord>.offset(of: \.parent)!)
            .advanced(by: parentOffset)
        let parentDescriptor = parentAddress.assumingMemoryBound(to: ContextDescriptorRecord.self)

        let parentName: String?
        switch parentDescriptor.pointee.flags.kind {
        case .module, .classType, .structType, .enumType:
            parentName = descriptorChainName(descriptor: parentDescriptor)
        default:
            parentName = nil
        }
        guard let parentName else {
            return ownName
        }
        return "\(parentName).\(ownName)"
    }

    private static func metadataAccessor(
        descriptor: UnsafePointer<ContextDescriptorRecord>
    ) -> (@convention(c) () -> UInt64)? {
        let accessorFieldOffset = MemoryLayout<ContextDescriptorRecord>.offset(of: \.accessFunction)!
        let accessorAddress = UnsafeRawPointer(descriptor)
            .advanced(by: accessorFieldOffset)
            .advanced(by: Int(descriptor.pointee.accessFunction))
        return unsafeBitCast(accessorAddress, to: (@convention(c) () -> UInt64).self)
    }
}
