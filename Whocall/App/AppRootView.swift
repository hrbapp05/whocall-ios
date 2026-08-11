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

    private var skipsOnboardingForUITest: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-uiTestAppShell")
#else
        false
#endif
    }

    var body: some View {
        Group {
            if !hasCompletedOnboarding && !skipsOnboardingForUITest {
                OnboardingView { hasCompletedOnboarding = true }
            } else if !session.isAuthenticated {
                AuthFlowView { session.isAuthenticated = true }
            } else {
                AppShellView { session.isAuthenticated = false }
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    AppRootView()
}
