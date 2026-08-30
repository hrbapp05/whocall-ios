import SwiftUI

private enum AppTab: Hashable {
    case home
    case history
    case profile
}

struct AppShellView: View {
    let onSignOut: () -> Void
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeFlowView(onVisibilityRequired: { selectedTab = .profile })
                .tabItem { Label("Anasayfa", systemImage: "house") }
                .tag(AppTab.home)
            HistoryView()
                .tabItem { Label("Geçmiş", systemImage: "phone.arrow.down.left") }
                .tag(AppTab.history)
            ProfileView(onSignOut: onSignOut)
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .tint(.primary)
    }
}
