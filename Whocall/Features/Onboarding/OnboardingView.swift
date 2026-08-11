import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var selection = OnboardingPage.unknownNumbers

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Image("WhoCallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 26)
                    .padding(.top, max(proxy.safeAreaInsets.top + 20, 48))

                TabView(selection: $selection) {
                    ForEach(OnboardingPage.allCases) { page in
                        pageContent(page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Button("Devam Et") {
                    advance()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DesignTokens.Spacing.large)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 6, 20))
                .accessibilityIdentifier("onboarding.continue")
            }
            .background(DesignTokens.ColorToken.background)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            OnboardingHero(page: page)
                .padding(.top, DesignTokens.Spacing.section)

            Spacer(minLength: DesignTokens.Spacing.small)

            Text(page.title)
                .font(.system(.largeTitle, design: .default, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(-2)
                .foregroundStyle(DesignTokens.ColorToken.primary)

            Text(page.message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignTokens.ColorToken.secondary)
                .padding(.horizontal, 28)
                .padding(.top, DesignTokens.Spacing.standard)

            Spacer(minLength: DesignTokens.Spacing.large)
        }
    }

    private func advance() {
        guard let index = OnboardingPage.allCases.firstIndex(of: selection) else { return }
        let nextIndex = OnboardingPage.allCases.index(after: index)
        guard nextIndex < OnboardingPage.allCases.endIndex else {
            onComplete()
            return
        }
        withAnimation(.easeInOut(duration: 0.28)) {
            selection = OnboardingPage.allCases[nextIndex]
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}

