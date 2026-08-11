import Observation
import SwiftUI

@MainActor
@Observable
final class AppSession {
    var isAuthenticated: Bool

    init() {
#if DEBUG
        isAuthenticated = ProcessInfo.processInfo.arguments.contains("-uiTestAppShell")
#else
        isAuthenticated = false
#endif
    }
}

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var session = AppSession()
    @State private var purchaseStore = PurchaseStore()

    private var skipsOnboardingForUITest: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uiTestAppShell")
#else
        false
#endif
    }

    var body: some View {
        Group {
            if let screen = uiTestScreen {
                UITestShowcaseView(screen: screen)
            } else if !hasCompletedOnboarding && !skipsOnboardingForUITest {
                OnboardingView { hasCompletedOnboarding = true }
            } else if !session.isAuthenticated {
                AuthFlowView { session.isAuthenticated = true }
            } else {
                AppShellView { session.isAuthenticated = false }
            }
        }
        .environment(purchaseStore)
        .task { await purchaseStore.start() }
        .preferredColorScheme(.light)
    }

    private var uiTestScreen: String? {
#if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-uiTestScreen"), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
#else
        nil
#endif
    }
}

private struct UITestShowcaseView: View {
    let screen: String

    var body: some View {
        NavigationStack {
            switch screen {
            case "onboarding": OnboardingView(onComplete: {})
            case "onboarding2": OnboardingView(initialPage: .scan, onComplete: {})
            case "onboarding3": OnboardingView(initialPage: .details, onComplete: {})
            case "login": LoginView()
            case "premium": PremiumView()
            case "credits": CreditsView()
            case "scanning": LookupProgressView(number: "5065055555", onResult: { _ in })
            case "person": PersonDetailView(name: "Ahmet S.", number: "905055055050", onComments: {})
            default: HomeView(onSearch: { _ in }, onRecord: { _ in }, onPremium: {})
            }
        }
    }
}

#Preview {
    AppRootView()
}
