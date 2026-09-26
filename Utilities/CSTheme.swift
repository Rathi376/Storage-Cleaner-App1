import SwiftUI
import UIKit

/// CleanSpace iOS Native Design System.
/// Uses Apple system colors, dynamic semantic colors for Light/Dark mode,
/// SF Symbols styling, glassmorphism, and haptic feedback.
enum CSTheme {

    // MARK: - Native iOS Semantic Colors

    /// Background adapted for system grouped style (supports light & dark mode)
    static var background: Color {
        Color(uiColor: .systemGroupedBackground)
    }

    /// Primary card background
    static var cardBackground: Color {
        Color(uiColor: .secondarySystemGroupedBackground)
    }

    /// Elevated surface background
    static var surfaceLight: Color {
        Color(uiColor: .tertiarySystemGroupedBackground)
    }

    /// System separator border
    static var cardBorder: Color {
        Color(uiColor: .separator).opacity(0.35)
    }

    // MARK: - Native Apple Accent Tints

    static let accentBlue = Color.blue
    static let accentIndigo = Color.indigo
    static let accentPurple = Color.purple
    static let accentPink = Color.pink
    static let accentOrange = Color.orange
    static let accentTeal = Color.teal
    static let accentCyan = Color.cyan
    static let accentGreen = Color.green
    static let accentMint = Color.mint
    static let accentRed = Color.red
    static let accentYellow = Color.yellow

    // MARK: - Typography Colors

    static var textPrimary: Color {
        Color(uiColor: .label)
    }

    static var textSecondary: Color {
        Color(uiColor: .secondaryLabel)
    }

    static var textTertiary: Color {
        Color(uiColor: .tertiaryLabel)
    }

    static var destructive: Color {
        Color.red
    }

    // MARK: - iOS Native Gradients

    static let primaryGradient = LinearGradient(
        colors: [Color.blue, Color(red: 0.35, green: 0.34, blue: 0.84)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let scanButtonGradient = LinearGradient(
        colors: [Color.blue, Color.cyan],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let deleteGradient = LinearGradient(
        colors: [Color.red, Color(red: 1.0, green: 0.35, blue: 0.45)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let successGradient = LinearGradient(
        colors: [Color.green, Color.teal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let storageGradient = LinearGradient(
        colors: [Color.blue, Color.purple, Color.orange, Color.pink],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Geometry & Metrics

    static let cardRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16

    // MARK: - Haptics

    @MainActor
    static func hapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    @MainActor
    static func hapticNotification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

// MARK: - Reusable Modifiers & Button Styles

struct CSBounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

extension View {
    /// Standard iOS card container
    func csCard(cornerRadius: CGFloat = CSTheme.cardRadius, padding: CGFloat = CSTheme.cardPadding) -> some View {
        self
            .padding(padding)
            .background(CSTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(CSTheme.cardBorder, lineWidth: 0.8)
            )
    }

    /// Glassmorphic frosted material card
    func csGlassCard(cornerRadius: CGFloat = CSTheme.cardRadius, padding: CGFloat = CSTheme.cardPadding) -> some View {
        self
            .padding(padding)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(CSTheme.cardBorder, lineWidth: 0.8)
            )
    }

    /// Apple-style primary action button
    func csPrimaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(CSTheme.scanButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    /// Apple-style destructive action button
    func csDestructiveButton() -> some View {
        self
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(CSTheme.deleteGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.red.opacity(0.3), radius: 8, x: 0, y: 4)
    }

    /// Apple-style secondary action button
    func csSecondaryButton() -> some View {
        self
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(CSTheme.accentBlue)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(CSTheme.accentBlue.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// Squircle icon container (like iOS Settings icons)
    func csIconBadge(color: Color, size: CGFloat = 40, iconSize: CGFloat = 18) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
                .shadow(color: color.opacity(0.25), radius: 4, x: 0, y: 2)

            self
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}
