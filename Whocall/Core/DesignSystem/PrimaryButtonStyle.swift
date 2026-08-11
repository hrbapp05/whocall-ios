import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 55)
            .foregroundStyle(DesignTokens.ColorToken.buttonLabel)
            .background(DesignTokens.ColorToken.button.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(.rect(cornerRadius: DesignTokens.Radius.button))
            .contentShape(.rect)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

