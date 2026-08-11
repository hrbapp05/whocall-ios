import Observation
import SwiftUI

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
#endif

@MainActor
@Observable
final class AppSession {
    var isAuthenticated: Bool

#if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
#endif

    init() {
#if DEBUG
        isAuthenticated = ProcessInfo.processInfo.arguments.contains("-uiTestAppShell")
#else
        isAuthenticated = false
#endif
    }

    func start() {
#if canImport(FirebaseAuth)
        guard authStateHandle == nil, FirebaseApp.app() != nil else { return }
        isAuthenticated = Auth.auth().currentUser != nil
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.isAuthenticated = user != nil
            }
        }
#endif
    }

    func signOut() {
#if canImport(FirebaseAuth)
        if FirebaseApp.app() != nil {
            try? Auth.auth().signOut()
        }
#endif
        isAuthenticated = false
    }

    var requiresProfileCompletion: Bool {
        let name = ProfileServiceFactory.live().currentDisplayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return name?.split(separator: " ").count ?? 0 < 2
    }
}

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var session = AppSession()
    @State private var purchaseStore = PurchaseStore()
    @State private var contactService = ContactService()
    @State private var recentLookupStore = RecentLookupStore()
    @State private var postAuthenticationFlow: PostAuthenticationPresentation?

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
                AuthFlowView {
                    session.isAuthenticated = true
                    postAuthenticationFlow = PostAuthenticationPresentation(
                        requiresProfileCompletion: session.requiresProfileCompletion
                    )
                }
            } else {
                AppShellView { session.signOut() }
            }
        }
        .environment(purchaseStore)
        .environment(contactService)
        .environment(recentLookupStore)
        .fullScreenCover(item: $postAuthenticationFlow) { presentation in
            PostAuthenticationFlowView(
                requiresProfileCompletion: presentation.requiresProfileCompletion
            ) {
                postAuthenticationFlow = nil
                Task { await contactService.requestAccessIfNeeded() }
            }
            .environment(purchaseStore)
        }
        .task {
            session.start()
            await purchaseStore.start()
        }
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

private struct PostAuthenticationPresentation: Identifiable {
    let id = UUID()
    let requiresProfileCompletion: Bool
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
