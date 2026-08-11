import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: 0) {
            Image("WhoCallLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 26)
                .padding(.top, 28)

            ZStack {
                Image("LoginHero")
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 410)

                Image("IntroStickerLaugh")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 76)
                    .offset(x: 125, y: -105)
            }
            .frame(maxHeight: .infinity)

            Text("WhoCall’a Hoş Geldin!")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Text("Numara sorgulamak, arayanı tanımak ve detayları görmek için hemen giriş yap.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
                .padding(.top, 12)

            NavigationLink("Giriş Yap", value: AuthRoute.phone)
                .buttonStyle(PrimaryButtonStyle())
                .padding(20)
                .accessibilityIdentifier("auth.login")
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

