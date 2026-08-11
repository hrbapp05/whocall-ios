import SwiftUI

struct OnboardingView: View {
    private let referenceSize = CGSize(width: 402, height: 874)

    let onComplete: () -> Void
    @State private var selection: OnboardingPage

    init(initialPage: OnboardingPage = .unknownNumbers, onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        _selection = State(initialValue: initialPage)
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / referenceSize.width,
                proxy.size.height / referenceSize.height
            )

            ZStack {
                TabView(selection: $selection) {
                    ForEach(OnboardingPage.allCases) { page in
                        pageCanvas(page)
                            .tag(page)
                            .scaleEffect(selection == page ? 1 : 0.94)
                            .opacity(selection == page ? 1 : 0.62)
                            .animation(.spring(duration: 0.58, bounce: 0.16), value: selection)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Button("Devam Et") {
                    advance()
                }
                .buttonStyle(PrimaryButtonStyle())
                .frame(width: 362, height: 55)
                .position(x: 201, y: 806.5)
                .figmaEntrance(delay: 0.30, distance: 14)
                .accessibilityIdentifier("onboarding.continue")
            }
            .frame(width: referenceSize.width, height: referenceSize.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(DesignTokens.ColorToken.background)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }

    private func pageCanvas(_ page: OnboardingPage) -> some View {
        ZStack {
            DesignTokens.ColorToken.background

            OnboardingHero(page: page)

            Image("WhoCallLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 26)
                .position(x: 201, y: 93)
                .figmaEntrance(delay: 0.02, distance: 8)

            Text(page.title)
                .font(.system(size: 35, weight: .bold))
                .multilineTextAlignment(.center)
                .lineSpacing(-2)
                .foregroundStyle(DesignTokens.ColorToken.primary)
                .frame(width: 362, height: 67, alignment: .center)
                .position(x: 201, y: 651.5)
                .figmaEntrance(delay: 0.16, distance: 12)

            Text(page.message)
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .foregroundStyle(DesignTokens.ColorToken.secondary)
                .lineSpacing(2)
                .frame(width: 350, height: page.messageHeight, alignment: .top)
                .position(x: 201, y: 705 + page.messageHeight / 2)
                .figmaEntrance(delay: 0.24, distance: 10)
        }
        .frame(width: referenceSize.width, height: referenceSize.height)
        .clipped()
    }

    private func advance() {
        guard let index = OnboardingPage.allCases.firstIndex(of: selection) else { return }
        let nextIndex = OnboardingPage.allCases.index(after: index)
        guard nextIndex < OnboardingPage.allCases.endIndex else {
            onComplete()
            return
        }
        withAnimation(.spring(duration: 0.62, bounce: 0.16)) {
            selection = OnboardingPage.allCases[nextIndex]
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
