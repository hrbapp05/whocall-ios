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
    private(set) var isResolvingAuthentication: Bool
    private(set) var userID: String?

#if canImport(FirebaseAuth)
    private var authStateHandle: AuthStateDidChangeListenerHandle?
#endif

    init() {
#if DEBUG
        let launchesAppShell = ProcessInfo.processInfo.arguments.contains("-uiTestAppShell")
        isAuthenticated = launchesAppShell
        isResolvingAuthentication = !launchesAppShell
        userID = launchesAppShell ? "ui-test-user" : nil
#else
        isAuthenticated = false
        isResolvingAuthentication = true
        userID = nil
#endif
    }

    func start() async {
#if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else {
            clearAuthentication()
            return
        }

        if authStateHandle == nil {
            authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                Task { @MainActor in
                    guard let self else { return }
                    guard let user else {
                        self.clearAuthentication()
                        return
                    }

                    // The first callback contains Firebase's cached user and can
                    // arrive while the server-backed validation below is running.
                    // Keep the loading state visible instead of briefly routing to
                    // the welcome screen. OTP completion validates new users through
                    // the explicit onAuthenticated callback.
                    if let userID = self.userID, user.uid != userID {
                        self.isAuthenticated = false
                        self.userID = nil
                        self.isResolvingAuthentication = true
                        _ = await self.refreshValidatedCurrentUser()
                    }
                }
            }
        }

        _ = await refreshValidatedCurrentUser()
#else
        clearAuthentication()
#endif
    }

    @discardableResult
    func refreshValidatedCurrentUser() async -> Bool {
#if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil, let candidate = Auth.auth().currentUser else {
            clearAuthentication()
            return false
        }

        isResolvingAuthentication = true

        do {
            try await candidate.reload()
            guard
                let currentUser = Auth.auth().currentUser,
                currentUser.uid == candidate.uid,
                let phoneNumber = currentUser.phoneNumber,
                !phoneNumber.isEmpty
            else {
                signOut()
                return false
            }

            // Keep callable Functions in sync with a phone credential that may
            // have been linked during the immediately preceding OTP flow.
            _ = try await currentUser.getIDToken(forcingRefresh: true)
            isAuthenticated = true
            isResolvingAuthentication = false
            userID = currentUser.uid
            return true
        } catch {
            // Deleted, disabled and otherwise invalid cached users must never
            // inherit access from a previous installation or account.
            signOut()
            return false
        }
#else
        clearAuthentication()
        return false
#endif
    }

    func signOut() {
#if canImport(FirebaseAuth)
        if FirebaseApp.app() != nil {
            try? Auth.auth().signOut()
        }
#endif
        isAuthenticated = false
        isResolvingAuthentication = false
        userID = nil
    }

    private func clearAuthentication() {
        isAuthenticated = false
        isResolvingAuthentication = false
        userID = nil
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
    @State private var recentLookupStore = RecentLookupStore()
    @State private var communityStore = CommunityStore()
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
            } else if session.isResolvingAuthentication {
                ZStack {
                    Color(uiColor: .systemBackground).ignoresSafeArea()
                    ProgressView("Oturum kontrol ediliyor…")
                        .tint(DesignTokens.ColorToken.brandBlue)
                }
            } else if !session.isAuthenticated {
                AuthFlowView {
                    Task {
                        guard await session.refreshValidatedCurrentUser() else { return }
                        await purchaseStore.activateAccount(session.userID)
                        await purchaseStore.refreshCustomerInfo()
                        postAuthenticationFlow = PostAuthenticationPresentation.make(
                            requiresProfileCompletion: session.requiresProfileCompletion,
                            isPremium: purchaseStore.isPremium
                        )
                    }
                }
            } else {
                AppShellView { session.signOut() }
            }
        }
        .environment(purchaseStore)
        .environment(recentLookupStore)
        .environment(communityStore)
        .fullScreenCover(item: $postAuthenticationFlow) { presentation in
            PostAuthenticationFlowView(
                requiresProfileCompletion: presentation.requiresProfileCompletion,
                showsPaywall: presentation.showsPaywall
            ) {
                postAuthenticationFlow = nil
            }
            .environment(purchaseStore)
        }
        .task {
            await session.start()
            recentLookupStore.activateAccount(session.userID)
            await purchaseStore.start(accountID: session.userID)
            await PendingVerifiedProfileStore.retryIfNeeded()
            await CurrentVerifiedProfileSynchronizer.synchronize()
        }
        .onChange(of: session.userID) { _, userID in
            recentLookupStore.activateAccount(userID)
            Task {
                await purchaseStore.activateAccount(userID)
                await CurrentVerifiedProfileSynchronizer.synchronize()
            }
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

struct PostAuthenticationPresentation: Identifiable, Equatable {
    let id = UUID()
    let requiresProfileCompletion: Bool
    let showsPaywall: Bool

    static func make(requiresProfileCompletion: Bool, isPremium: Bool) -> Self? {
        let showsPaywall = !isPremium
        guard showsPaywall || requiresProfileCompletion else { return nil }
        return Self(
            requiresProfileCompletion: requiresProfileCompletion,
            showsPaywall: showsPaywall
        )
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
            case "phone": PhoneEntryView(onAuthenticated: {}, authService: DevelopmentAuthService())
            case "otp": OTPView(
                verificationID: "development-verification",
                phoneNumber: "+905065055555",
                onAuthenticated: {},
                authService: DevelopmentAuthService()
            )
            case "premium": PremiumView()
            case "credits": CreditsView()
            case "scanning": LookupProgressView(number: "5065055555", onResult: { _ in })
            case "person": PersonDetailView(
                name: "Ahmet S.",
                number: "905055055050",
                onComments: {},
                onAddComment: {},
                onCredits: {}
            )
            case "comments": CommentsView(personName: "Ahmet S.", phoneNumber: "905055055050")
            case "result": ResultView(
                owner: PhoneOwner(
                    phoneNumber: "905055055050",
                    displayName: "Ahmet S.",
                    firstName: "Ahmet",
                    lastName: "S."
                ),
                onDetails: {},
                onNewLookup: {},
                onCredits: {}
            )
            case "profile": ProfileView(onSignOut: {})
            default: HomeView(onSearch: { _ in }, onRecord: { _ in }, onPremium: {}, onCredits: {})
            }
        }
    }
}

#Preview {
    AppRootView()
}
