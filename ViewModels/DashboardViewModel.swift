import SwiftUI
import Photos
import Contacts

/// Drives the main dashboard screen.
/// Shows storage info, category summaries, and scan state.
@MainActor
@Observable
final class DashboardViewModel {

    // MARK: - State

    var storageInfo: StorageInfo = .empty
    var isScanning = false
    var scanProgress: ScanProgress = .idle
    var hasScanned = false

    // Category counts
    var similarPhotoCount = 0
    var screenshotCount = 0
    var largeVideoCount = 0
    var duplicateContactCount = 0
    var blurryPhotoCount = 0

    // Category sizes
    var similarPhotoBytes: Int64 = 0
    var screenshotBytes: Int64 = 0
    var largeVideoBytes: Int64 = 0
    var blurryPhotoBytes: Int64 = 0

    // Results stored after scan
    var photoScanResult: PhotoScanResult = .empty
    var screenshots: [PhotoItem] = []
    var videos: [VideoItem] = []
    var contactScanResult: ContactScanResult = .empty
    var blurryPhotos: [PhotoItem] = []

    // Permission state
    var photosPermission: PHAuthorizationStatus = .notDetermined
    var contactsPermission: CNAuthorizationStatus = .notDetermined

    // Navigation
    var showPermissionAlert = false
    var permissionAlertMessage = ""
    var showPrePermissionExplanation = false

    var reclaimableBytes: Int64 {
        similarPhotoBytes + screenshotBytes + largeVideoBytes + blurryPhotoBytes
    }

    // MARK: - Init

    init() {
        refreshStorageInfo()
        refreshPermissions()
    }

    // MARK: - Storage

    func refreshStorageInfo() {
        var info = StorageService.shared.getStorageInfo()
        info.reclaimableBytes = reclaimableBytes
        storageInfo = info
    }

    func refreshPermissions() {
        photosPermission = PhotoLibraryService.shared.authorizationStatus
        contactsPermission = ContactsService.shared.authorizationStatus
    }

    // MARK: - Scan Action

    func handleScanTap() {
        refreshPermissions()
        if photosPermission == .notDetermined {
            showPrePermissionExplanation = true
        } else {
            startFullScan()
        }
    }

    // MARK: - Full Scan

    func startFullScan() {
        guard !isScanning else { return }
        isScanning = true
        scanProgress = ScanProgress(currentStep: "Preparing…", processedCount: 0, totalCount: 0, isComplete: false)

        Task {
            await scanPhotos()
            await scanBlurryPhotos()
            await scanScreenshots()
            await scanVideos()
            await scanContacts()

            isScanning = false
            hasScanned = true
            refreshStorageInfo()
        }
    }

    // MARK: - Photo Scan

    private func scanPhotos() async {
        let status = await PhotoLibraryService.shared.requestAuthorization()
        photosPermission = status

        guard status == .authorized || status == .limited else {
            scanProgress = ScanProgress(currentStep: "Photos access denied", processedCount: 0, totalCount: 0, isComplete: false)
            return
        }

        let assets = PhotoLibraryService.shared.fetchAllPhotos()
        let result = await PhotoSimilarityService.shared.findSimilarPhotos(
            assets: assets,
            onProgress: { [weak self] progress in
                self?.scanProgress = progress
            }
        )

        photoScanResult = result
        similarPhotoCount = result.totalDuplicateCount
        similarPhotoBytes = result.groups.reduce(0) { total, group in
            total + group.items.dropFirst().reduce(0) { $0 + $1.estimatedBytes }
        }
    }

    // MARK: - Screenshot Scan

    private func scanScreenshots() async {
        guard PhotoLibraryService.shared.isAuthorized else { return }

        let assets = PhotoLibraryService.shared.fetchScreenshots()
        scanProgress = ScanProgress(currentStep: "Scanning screenshots…", processedCount: 0, totalCount: assets.count, isComplete: false)

        let items = await VideoScannerService.shared.scanScreenshots(
            assets: assets,
            onProgress: { [weak self] progress in
                self?.scanProgress = progress
            }
        )

        screenshots = items
        screenshotCount = items.count
        screenshotBytes = items.reduce(0) { $0 + $1.estimatedBytes }
    }

    // MARK: - Video Scan

    private func scanVideos() async {
        guard PhotoLibraryService.shared.isAuthorized else { return }

        let assets = PhotoLibraryService.shared.fetchVideos()
        scanProgress = ScanProgress(currentStep: "Scanning videos…", processedCount: 0, totalCount: assets.count, isComplete: false)

        let items = await VideoScannerService.shared.scanLargeVideos(
            assets: assets,
            onProgress: { [weak self] progress in
                self?.scanProgress = progress
            }
        )

        videos = items
        largeVideoCount = items.count
        largeVideoBytes = items.reduce(0) { $0 + $1.estimatedBytes }
    }

    // MARK: - Contact Scan

    private func scanContacts() async {
        let authorized = await ContactsService.shared.requestAuthorization()
        contactsPermission = ContactsService.shared.authorizationStatus

        guard authorized else {
            return
        }

        scanProgress = ScanProgress(currentStep: "Scanning contacts…", processedCount: 0, totalCount: 0, isComplete: false)

        do {
            let result = try await ContactsService.shared.scanForDuplicates()
            contactScanResult = result
            duplicateContactCount = result.totalDuplicateCount
        } catch {
            // Handle gracefully, contacts scan failed
            duplicateContactCount = 0
        }
    }

    // MARK: - Blurry Photo Scan

    private func scanBlurryPhotos() async {
        guard PhotoLibraryService.shared.isAuthorized else { return }

        let assets = PhotoLibraryService.shared.fetchAllPhotos()
        scanProgress = ScanProgress(currentStep: "Analyzing photo sharpness…", processedCount: 0, totalCount: min(assets.count, 250), isComplete: false)

        let items = await BlurDetectionService.shared.scanBlurryPhotos(
            assets: assets,
            onProgress: { [weak self] progress in
                self?.scanProgress = progress
            }
        )

        blurryPhotos = items
        blurryPhotoCount = items.count
        blurryPhotoBytes = items.reduce(0) { $0 + $1.estimatedBytes }
    }
}
