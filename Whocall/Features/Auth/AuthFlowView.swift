import SwiftUI

struct AuthFlowView: View {
    let onAuthenticated: () -> Void

    var body: some View {
        NavigationStack {
            LoginView()
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
