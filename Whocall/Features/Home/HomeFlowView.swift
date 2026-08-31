import SwiftUI
import StoreKit

struct HomeFlowView: View {
    let onVisibilityRequired: () -> Void
    @Environment(PurchaseStore.self) private var purchaseStore
    @Environment(RecentLookupStore.self) private var recentLookupStore
    @Environment(\.requestReview) private var requestReview
    @State private var path: [HomeRoute] = []
    @State private var hasPendingReviewRequest = false

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSearch: { path.append(.lookup($0)) },
                onRecord: { path.append(.person($0.displayName, $0.phoneNumber)) },
                onPremium: { path.append(.premium) },
                onCredits: { path.append(.credits) },
                onVisibilityRequired: onVisibilityRequired
            )
            .navigationDestination(for: HomeRoute.self) { route in
                destination(route)
            }
        }
        .task(id: shouldRequestReviewOnHome) {
            guard shouldRequestReviewOnHome else { return }
            try? await Task.sleep(for: .seconds(1))
            guard !Task.isCancelled, path.isEmpty,
                  ReviewPromptStore.canRequestAfterFirstPromoLookup()
            else { return }
            ReviewPromptStore.markFirstPromoLookupRequest()
            hasPendingReviewRequest = false
            requestReview()
        }
    }

    @ViewBuilder
    private func destination(_ route: HomeRoute) -> some View {
        switch route {
        case let .lookup(number):
            LookupProgressView(
                number: number,
                onOutcome: { outcome in
                    switch outcome {
                    case let .found(owner):
                        Task { @MainActor in
                            let promotionalBalanceBeforeLookup = purchaseStore.promotionalCreditBalance
                            let isUsingFirstPromotionalCredit = !purchaseStore.isPremium &&
                                purchaseStore.purchasedCreditBalance == 0 &&
                                promotionalBalanceBeforeLookup > 0 &&
                                ReviewPromptStore.canRequestAfterFirstPromoLookup()
                            guard await purchaseStore.authorizeLookupResult() else {
                                if !path.isEmpty { path.removeLast() }
                                path.append(.premium)
                                return
                            }
                            if isUsingFirstPromotionalCredit &&
                                purchaseStore.promotionalCreditBalance < promotionalBalanceBeforeLookup {
                                hasPendingReviewRequest = true
                            }
                            recentLookupStore.record(owner: owner)
                            replaceLookup(with: .result(owner))
                        }
                    case .hidden:
                        replaceLookup(with: .unavailable(.hidden, number))
                    case .requesterHidden:
                        replaceLookup(with: .unavailable(.requesterHidden, number))
                    case .notFound:
                        replaceLookup(with: .unavailable(.notFound, number))
                    }
                },
                onCredits: { path.append(.credits) }
            )
        case let .result(owner):
            ResultView(
                owner: owner,
                onDetails: { path.append(.person(owner.displayName, owner.phoneNumber)) },
                onNewLookup: { path.removeAll() },
                onCredits: { path.append(.credits) }
            )
        case let .person(name, number):
            PersonDetailView(
                name: name,
                number: number,
                onComments: { path.append(.comments(name, number, false)) },
                onAddComment: { path.append(.comments(name, number, true)) },
                onCredits: { path.append(.credits) }
            )
        case let .comments(name, number, startsComposing):
            CommentsView(personName: name, phoneNumber: number, startsComposing: startsComposing)
        case let .unavailable(reason, number):
            LookupUnavailableView(
                reason: reason,
                number: number,
                onNewLookup: {
                    path.removeAll()
                    if reason == .requesterHidden { onVisibilityRequired() }
                }
            )
        case .premium:
            PremiumView()
        case .credits:
            CreditsView()
        }
    }

    private func replaceLookup(with route: HomeRoute) {
        // Replace the progress screen so Back never replays the scanner.
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }

    private var shouldRequestReviewOnHome: Bool {
        hasPendingReviewRequest && path.isEmpty &&
            ReviewPromptStore.canRequestAfterFirstPromoLookup()
    }
}

extension HomeFlowView {
    init() {
        self.init(onVisibilityRequired: {})
    }
}

enum HomeRoute: Hashable {
    case lookup(String)
    case result(PhoneOwner)
    case person(String, String)
    case comments(String, String, Bool)
    case unavailable(LookupUnavailableReason, String)
    case premium
    case credits
}
