import SwiftUI

struct HomeFlowView: View {
    @State private var path: [HomeRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onSearch: { path.append(.lookup($0)) },
                onRecord: { path.append(.person($0.displayName, $0.phoneNumber)) },
                onPremium: { path.append(.premium) }
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
            LookupProgressView(number: number) { owner in
                path.append(.result(owner))
            }
        case let .result(owner):
            ResultView(owner: owner, onDetails: { path.append(.person(owner.displayName, owner.phoneNumber)) })
        case let .person(name, number):
            PersonDetailView(name: name, number: number) { path.append(.comments) }
        case .comments:
            CommentsView()
        case .premium:
            PremiumView()
        }
    }
}

enum HomeRoute: Hashable {
    case lookup(String)
    case result(PhoneOwner)
    case person(String, String)
    case comments
    case premium
}

