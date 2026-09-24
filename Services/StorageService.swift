import Foundation

/// Reads device storage information using FileManager system attributes.
/// All calculations happen locally on-device.
final class StorageService: Sendable {

    static let shared = StorageService()

    private init() {}

    /// Fetches current device storage info.
    func getStorageInfo() -> StorageInfo {
        let home = URL(fileURLWithPath: NSHomeDirectory())
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: home.path) else {
            return .empty
        }

        let totalBytes = (attrs[.systemSize] as? Int64) ?? 0
        let freeBytes = (attrs[.systemFreeSize] as? Int64) ?? 0
        let usedBytes = totalBytes - freeBytes

        return StorageInfo(
            totalBytes: totalBytes,
            usedBytes: usedBytes,
            freeBytes: freeBytes,
            reclaimableBytes: 0  // updated after scan
        )
    }
}
