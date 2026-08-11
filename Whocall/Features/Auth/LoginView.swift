import SwiftUI

struct LoginView: View {
    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Image("WhoCallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 26)
                    .padding(.top, 20)
                    .figmaEntrance(delay: 0.02, distance: 8)
                    .zIndex(4)
                    .fixedSize()
                    .layoutPriority(2)

                emojiOrbit
                    .frame(height: min(484, proxy.size.height * 0.57))
                    .clipped()

                Text("WhoCall'a Hoş Geldin!")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .figmaEntrance(delay: 0.18, distance: 14)

                Text("Numara Sorgulamak, Arayanı Tanımak Ve Detayları\nGörmek İçin Hemen Giriş Yap.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
                    .padding(.top, 14)
                    .figmaEntrance(delay: 0.24, distance: 12)

                Spacer(minLength: 18)

                NavigationLink("Giriş Yap", value: AuthRoute.phone)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 20)
                    .padding(.bottom, max(proxy.safeAreaInsets.bottom + 6, 14))
                    .figmaEntrance(delay: 0.32, distance: 16)
                    .accessibilityIdentifier("auth.login")
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var emojiOrbit: some View {
        ZStack {
            Image("LoginAppIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 267, height: 266)
                .figmaEntrance(delay: 0.08, distance: 0)
                .gentleFloat(distance: 5, duration: 2.4)

            ForEach(0..<12, id: \.self) { index in
                Image("LoginEmoji\(index)")
                    .resizable()
                    .scaledToFit()
                    .frame(width: emojiSize(index), height: emojiSize(index))
                    .offset(emojiOffset(index))
                    .gentleFloat(
                        distance: 4 + CGFloat(index % 3),
                        duration: 1.9 + Double(index % 4) * 0.22,
                        delay: Double(index) * 0.04
                    )
                    .figmaEntrance(delay: 0.05 + Double(index) * 0.025, distance: 10)
            }

            Image("IntroStickerLove")
                .resizable().scaledToFit().frame(width: 64)
                .offset(x: -126, y: -118)
                .gentleFloat(distance: 5, duration: 2.2, delay: 0.2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emojiOffset(_ index: Int) -> CGSize {
        let positions: [CGSize] = [
            .init(width: -71, height: -120), .init(width: 4, height: -134),
            .init(width: 82, height: -122), .init(width: 139, height: -55),
            .init(width: 144, height: 35), .init(width: 99, height: 105),
            .init(width: 24, height: 132), .init(width: -56, height: 120),
            .init(width: -124, height: 75), .init(width: -151, height: 0),
            .init(width: -136, height: -70), .init(width: 57, height: -54)
        ]
        return positions[index]
    }

    private func emojiSize(_ index: Int) -> CGFloat {
        [52, 58, 56, 62, 58, 61, 58, 60, 55, 58, 54, 50][index]
    }
}
