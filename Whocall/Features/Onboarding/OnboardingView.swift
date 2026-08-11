import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var selection: OnboardingPage

    init(initialPage: OnboardingPage = .unknownNumbers, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _selection = State(initialValue: initialPage)
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Image("WhoCallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 26)
                    .padding(.top, 20)

                TabView(selection: $selection) {
                    ForEach(OnboardingPage.allCases) { page in
                        pageContent(page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: min(650, proxy.size.height * 0.74))

                Button("Devam Et") {
                    advance()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, DesignTokens.Spacing.large)
                .padding(.bottom, max(proxy.safeAreaInsets.bottom + 6, 14))
                .accessibilityIdentifier("onboarding.continue")
            }
            .background(DesignTokens.ColorToken.background)
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private func pageContent(_ page: OnboardingPage) -> some View {
        VStack(spacing: 0) {
            OnboardingHero(page: page)
                .frame(maxHeight: .infinity)

            Text(page.title)
                .font(.system(size: 35, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(-4)
                .foregroundStyle(DesignTokens.ColorToken.primary)
                .figmaEntrance(delay: 0.16, distance: 12)

            Text(page.message)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignTokens.ColorToken.secondary)
                .lineSpacing(2)
                .padding(.horizontal, 26)
                .padding(.top, 14)
                .figmaEntrance(delay: 0.24, distance: 10)
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
