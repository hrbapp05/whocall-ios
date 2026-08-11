import SwiftUI

struct AppRootView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                ContentUnavailableView(
                    "WhoCall",
                    systemImage: "phone.badge.waveform",
                    description: Text("Ana uygulama akışı bir sonraki milestone’da bağlanacak.")
                )
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    AppRootView()
}

