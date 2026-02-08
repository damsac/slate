import SwiftUI

enum Theme {
    // MARK: - Colors

    static let accent = Color.accentColor
    static let background = Color(.systemBackground)
    static let surface = Color(.secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static let priorityHigh = Color.red
    static let priorityMedium = Color.orange
    static let priorityLow = Color.blue

    static let success = Color.green
    static let destructive = Color.red

    // MARK: - Spacing

    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 12
    static let spacingLG: CGFloat = 16
    static let spacingXL: CGFloat = 24

    // MARK: - Corner Radius

    static let radiusSM: CGFloat = 8
    static let radiusMD: CGFloat = 12
    static let radiusLG: CGFloat = 16

    // MARK: - Helpers

    static func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .high: priorityHigh
        case .medium: priorityMedium
        case .low: priorityLow
        }
    }
}
