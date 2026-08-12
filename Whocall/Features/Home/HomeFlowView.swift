import SwiftUI

struct HomeFlowView: View {
    @Environment(PurchaseStore.self) private var purchaseStore
    @Environment(RecentLookupStore.self) private var recentLookupStore
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSearch: { path.append(.lookup($0)) },
                onRecord: { path.append(.person($0.displayName, $0.phoneNumber)) },
                onPremium: { path.append(.premium) },
                onCredits: { path.append(.credits) }
            )
            .navigationDestination(for: HomeRoute.self) { route in
                destination(route)
            }
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
                        guard purchaseStore.authorizeLookupResult() else {
                            if !path.isEmpty { path.removeLast() }
                            path.append(.premium)
                            return
                        }
                        recentLookupStore.record(owner: owner)
                        replaceLookup(with: .result(owner))
                    case .hidden:
                        replaceLookup(with: .unavailable(.hidden, number))
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
                onNewLookup: { path.removeAll() }
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
