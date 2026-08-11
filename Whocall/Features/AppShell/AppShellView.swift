import SwiftUI

struct AppShellView: View {
    let onSignOut: () -> Void

    var body: some View {
        TabView {
            HomeFlowView()
                .tabItem { Label("Anasayfa", systemImage: "house") }
            HistoryView()
                .tabItem { Label("Geçmiş", systemImage: "phone.arrow.down.left") }
            ProfileView(onSignOut: onSignOut)
                .tabItem { Label("Profil", systemImage: "person.crop.circle") }
        }
        .tint(.primary)
    }
}

