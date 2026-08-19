import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimated = false

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.background
                .ignoresSafeArea()

            Circle()
                .fill(DesignTokens.ColorToken.brandBlue.opacity(0.08))
                .frame(width: 250, height: 250)
                .scaleEffect(isAnimated ? 1.08 : 0.88)
                .opacity(isAnimated ? 0.42 : 0.8)

            VStack(spacing: 22) {
                Image("LoginAppIcon")
                    .resizable()
                    .frame(width: 243, height: 242)
                    .offset(y: 26)
                    .frame(width: 112, height: 112)
                    .clipShape(.rect(cornerRadius: 25))
                    .shadow(color: DesignTokens.ColorToken.brandBlue.opacity(0.16), radius: 24, y: 12)

                Image("WhoCallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 32)
            }
            .scaleEffect(isAnimated ? 1 : 0.92)
            .opacity(isAnimated ? 1 : 0.72)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("WhoCall")
        .task {
            withAnimation(.easeOut(duration: 0.55)) {
                isAnimated = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
