import SwiftUI
import Photos
import Contacts

/// Settings view highlighting privacy-first architecture, system permissions, and preferences.
struct SettingsView: View {
    @Environment(DashboardViewModel.self) private var dashboardVM
    @State private var photoStatus: PHAuthorizationStatus = .notDetermined
    @State private var contactStatus: CNAuthorizationStatus = .notDetermined

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Privacy Hero
                privacyHeroCard

                // Permissions Section
                permissionsCard

                // Privacy Commitments
                privacyPledgeCard

                // App Info Card
                appInfoCard

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
        .background(CSTheme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            refreshPermissions()
        }
    }

    // MARK: - Privacy Hero

    private var privacyHeroCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(CSTheme.accentCyan.opacity(0.15))
                    .frame(width: 64, height: 64)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(CSTheme.accentCyan)
            }

            Text("100% On-Device & Private")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("CleanSpace processes all photos, videos, and contacts exclusively on your iPhone. Zero analytics, zero data collection, zero network uploads.")
                .font(.system(size: 13))
                .foregroundStyle(CSTheme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .csCard()
    }

    // MARK: - Permissions

    private var permissionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Permissions")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            // Photos
            HStack {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(CSTheme.accentPurple)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo Library")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(photoStatusDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(CSTheme.textSecondary)
                }

                Spacer()

                Button("Manage") {
                    openSettings()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CSTheme.accentCyan)
            }

            Divider()
                .overlay(CSTheme.cardBorder)

            // Contacts
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(CSTheme.accentPink)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Contacts")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(CSTheme.textPrimary)
                    Text(contactStatusDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(CSTheme.textSecondary)
                }

                Spacer()

                Button("Manage") {
                    openSettings()
                }
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(CSTheme.accentPink)
            }
        }
        .csCard()
    }

    // MARK: - Privacy Commitments

    private var privacyPledgeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Our Guarantees")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            guaranteeRow(icon: "network.slash", text: "No Internet Connection Used", color: CSTheme.accentGreen)
            guaranteeRow(icon: "person.crop.circle.badge.xmark", text: "No Accounts or Sign In Required", color: CSTheme.accentCyan)
            guaranteeRow(icon: "creditcard.trianglebadge.exclamationmark", text: "100% Free Forever, No Paywalls", color: CSTheme.accentOrange)
            guaranteeRow(icon: "hand.raised.slash.fill", text: "Never Deletes Without Explicit Confirmation", color: CSTheme.accentPink)
        }
        .csCard()
    }

    private func guaranteeRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(CSTheme.textSecondary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(CSTheme.accentGreen)
        }
    }

    // MARK: - App Info

    private var appInfoCard: some View {
        VStack(spacing: 8) {
            Text("CleanSpace")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(CSTheme.textPrimary)

            Text("Version 1.0.0 • Production Release")
                .font(.system(size: 12))
                .foregroundStyle(CSTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var photoStatusDescription: String {
        switch photoStatus {
        case .authorized: return "Full Access granted"
        case .limited: return "Limited Access granted"
        case .denied, .restricted: return "Access denied"
        case .notDetermined: return "Not determined"
        @unknown default: return "Unknown"
        }
    }

    private var contactStatusDescription: String {
        switch contactStatus {
        case .authorized: return "Access granted"
        case .denied, .restricted: return "Access denied"
        case .notDetermined: return "Not determined"
        case .limited: return "Limited Access granted"
        @unknown default: return "Unknown"
        }
    }

    private func refreshPermissions() {
        photoStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        contactStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}
