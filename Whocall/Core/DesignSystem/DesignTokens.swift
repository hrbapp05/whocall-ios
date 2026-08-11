import SwiftUI

enum DesignTokens {
    enum Spacing {
        static let small: CGFloat = 8
        static let standard: CGFloat = 16
        static let large: CGFloat = 20
        static let section: CGFloat = 28
    }

    enum Radius {
        static let card: CGFloat = 20
        static let button: CGFloat = 28
        static let device: CGFloat = 34
    }

    enum ColorToken {
        static let background = Color(uiColor: .systemBackground)
        static let primary = Color.primary
        static let secondary = Color(uiColor: .secondaryLabel)
        static let button = Color(uiColor: .label)
        static let buttonLabel = Color(uiColor: .systemBackground)
        static let brandBlue = Color(red: 14 / 255, green: 138 / 255, blue: 252 / 255)
        static let mint = Color(red: 194 / 255, green: 244 / 255, blue: 236 / 255)
        static let card = Color(uiColor: .secondarySystemBackground)
        static let success = Color(red: 21 / 255, green: 184 / 255, blue: 65 / 255)
    }
}
