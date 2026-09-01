import SwiftUI

struct AuthFlowView: View {
    let onAuthenticated: () -> Void
    @State private var path: [AuthRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            LoginView {
                path.append(.phone)
            }
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .phone:
                        PhoneEntryView(onAuthenticated: onAuthenticated)
                    }
                }
        }
    }
}

enum AuthRoute: Hashable {
    case phone
}
