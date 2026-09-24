import SwiftUI

/// CleanSpace design system.
/// Custom color palette, gradients, and reusable styling.
enum CSTheme {

    // MARK: - Colors

    static let background = Color(red: 0.06, green: 0.06, blue: 0.10)
    static let cardBackground = Color(red: 0.10, green: 0.11, blue: 0.16)
    static let cardBorder = Color.white.opacity(0.06)
    static let surfaceLight = Color(red: 0.14, green: 0.15, blue: 0.20)

    static let accentCyan = Color(red: 0.25, green: 0.85, blue: 0.95)
    static let accentPurple = Color(red: 0.55, green: 0.35, blue: 0.95)
    static let accentPink = Color(red: 0.95, green: 0.35, blue: 0.60)
    static let accentGreen = Color(red: 0.30, green: 0.90, blue: 0.55)
    static let accentOrange = Color(red: 1.0, green: 0.60, blue: 0.20)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.65)
    static let textTertiary = Color.white.opacity(0.40)

    static let destructive = Color(red: 0.95, green: 0.30, blue: 0.30)

    // MARK: - Gradients

    static let primaryGradient = LinearGradient(
        colors: [accentCyan, accentPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let scanButtonGradient = LinearGradient(
        colors: [accentCyan, Color(red: 0.35, green: 0.65, blue: 0.95)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let deleteGradient = LinearGradient(
        colors: [accentPink, destructive],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let successGradient = LinearGradient(
        colors: [accentGreen, accentCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let storageGradient = LinearGradient(
        colors: [accentPurple, accentPink, accentOrange],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Card Style

    static let cardRadius: CGFloat = 18
    static let cardPadding: CGFloat = 16
}

// MARK: - Reusable Modifiers

extension View {
    func csCard() -> some View {
        self
            .padding(CSTheme.cardPadding)
            .background(CSTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: CSTheme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CSTheme.cardRadius)
                    .stroke(CSTheme.cardBorder, lineWidth: 1)
            )
    }

    func csPrimaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(CSTheme.scanButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func csDestructiveButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(CSTheme.deleteGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    func csSecondaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(CSTheme.accentCyan)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(CSTheme.accentCyan.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
