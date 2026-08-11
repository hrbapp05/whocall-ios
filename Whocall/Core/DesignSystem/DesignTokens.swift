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
    }
}

