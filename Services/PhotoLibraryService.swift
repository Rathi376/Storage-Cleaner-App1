import Photos
import UIKit
import AVFoundation

/// Provides access to the photo library, fetching assets and thumbnails.
/// All processing is on-device. No data leaves the device.
final class PhotoLibraryService: Sendable {

    static let shared = PhotoLibraryService()

    private let imageManager = PHCachingImageManager()

    private init() {
        imageManager.allowsCachingHighQualityImages = false
    }

    // MARK: - Authorization

    /// Current authorization status.
    var authorizationStatus: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    /// Request Photos access. Returns the resulting status.
    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    var isAuthorized: Bool {
        let status = authorizationStatus
        return status == .authorized || status == .limited
    }

    var isLimited: Bool {
        authorizationStatus == .limited
    }

    // MARK: - Fetching

    /// Fetch all image assets sorted by creation date.
    func fetchAllPhotos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Fetch only screenshot assets.
    func fetchScreenshots() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(
            format: "mediaType == %d AND (mediaSubtypes & %d) != 0",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    /// Fetch all video assets sorted by estimated size descending.
    func fetchVideos() -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    // MARK: - Thumbnails

    /// Load a thumbnail for the given asset. Uses a small target size.
    func loadThumbnail(for asset: PHAsset, targetSize: CGSize = CGSize(width: 200, height: 200)) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = false
            options.resizeMode = .fast
            options.isSynchronous = false

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded {
                    continuation.resume(returning: image)
                }
            }
        }
    }

    /// Estimate file size for a photo asset using resource data.
    func estimateFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        // Prefer the full-size photo resource
        if let resource = resources.first(where: { $0.type == .photo }) ?? resources.first {
            if let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
                return size
            }
        }
        // Fallback: estimate from pixel dimensions
        let bytesPerPixel: Int64 = 4
        return Int64(asset.pixelWidth) * Int64(asset.pixelHeight) * bytesPerPixel / 8
    }

    /// Estimate file size for a video asset using resources.
    func estimateVideoFileSize(for asset: PHAsset) -> Int64 {
        let resources = PHAssetResource.assetResources(for: asset)
        if let resource = resources.first(where: { $0.type == .video }) ?? resources.first {
            if let size = resource.value(forKey: "fileSize") as? Int64, size > 0 {
                return size
            }
        }
        // Rough fallback: ~5MB per minute of video
        return Int64(asset.duration * 5_000_000 / 60)
    }

    // MARK: - Video Playback

    /// Request AVPlayerItem for a video asset.
    func requestPlayerItem(for asset: PHAsset) async -> AVPlayerItem? {
        await withCheckedContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = false
            options.deliveryMode = .highQualityFormat
            imageManager.requestPlayerItem(forVideo: asset, options: options) { item, _ in
                continuation.resume(returning: item)
            }
        }
    }

    // MARK: - Deletion

    /// Delete the specified assets. Requires user confirmation via system dialog.
    func deleteAssets(identifiers: [String]) async throws {
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        var assets: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }

        guard !assets.isEmpty else { return }

        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
}

