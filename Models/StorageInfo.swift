import Foundation

/// Represents device storage information gathered from FileManager.
struct StorageInfo: Sendable {
    let totalBytes: Int64
    let usedBytes: Int64
    let freeBytes: Int64
    var reclaimableBytes: Int64

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes)
    }

    var freePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(freeBytes) / Double(totalBytes)
    }

    static let empty = StorageInfo(totalBytes: 0, usedBytes: 0, freeBytes: 0, reclaimableBytes: 0)
}

/// Formats byte counts into human-readable strings.
enum ByteFormatter: Sendable {
    static func string(from bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    static func string(from bytes: UInt64) -> String {
        string(from: Int64(clamping: bytes))
    }
}

