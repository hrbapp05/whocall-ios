import SwiftUI

struct LoginView: View {
    private let referenceSize = CGSize(width: 402, height: 874)

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / referenceSize.width,
                proxy.size.height / referenceSize.height
            )

            ZStack {
                DesignTokens.ColorToken.background

                Image("WhoCallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 26)
                    .position(x: 201, y: 93)
                    .figmaEntrance(delay: 0.02, distance: 8)

                Image("LoginAppIcon")
                    .resizable()
                    .frame(width: 267, height: 266)
                    .offset(y: 28.5)
                    .frame(width: 123, height: 122)
                    .clipShape(.rect(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.11), radius: 26, y: 14)
                    .position(x: 201.5, y: 364)
                    .popEntrance(delay: 0.12, initialScale: 0.34)
                    .gentleFloat(distance: 3, duration: 2.7)
                    // Figma places the app icon above the surrounding memojis.
                    // This keeps the overlapping faces behind its rounded card.
                    .zIndex(3)

                ForEach(Array(emojiLayout.enumerated()), id: \.offset) { index, emoji in
                    Image(emoji.asset)
                        .resizable()
                        .scaledToFit()
                        .frame(width: emoji.size, height: emoji.size)
                        .rotationEffect(.degrees(emoji.rotation))
                        .position(x: emoji.center.x, y: emoji.center.y)
                        .popEntrance(
                            delay: 0.06 + Double(index) * 0.055,
                            initialScale: 0.015
                        )
                        .gentleFloat(
                            distance: 3 + CGFloat(index % 3),
                            duration: 2 + Double(index % 4) * 0.2,
                            delay: Double(index) * 0.035
                        )
                        .zIndex(2)
                }

                welcomeTitle
                    .frame(width: 362, height: 38)
                    .position(x: 201, y: 676)
                    .figmaEntrance(delay: 0.25, distance: 13)

                Text("Numara Sorgulamak, Arayanı Tanımak Ve Detayları\nGörmek İçin Hemen Giriş Yap.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(red: 124 / 255, green: 124 / 255, blue: 124 / 255))
                    .multilineTextAlignment(.center)
                    .lineSpacing(1)
                    .lineLimit(2)
                    .frame(width: 362)
                    .fixedSize(horizontal: false, vertical: true)
                    .position(x: 201, y: 728)
                    .figmaEntrance(delay: 0.31, distance: 11)

                NavigationLink(value: AuthRoute.phone) {
                    Text("Giriş Yap")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 364, height: 60)
                        .background(.black, in: .capsule)
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .position(x: 202, y: 810)
                .figmaEntrance(delay: 0.38, distance: 16)
                .accessibilityIdentifier("auth.login")
            }
            .frame(width: referenceSize.width, height: referenceSize.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
            .background(DesignTokens.ColorToken.background)
        }
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }

    private var welcomeTitle: some View {
        (Text("WhoCall").fontWeight(.bold) + Text("'a Hoş Geldin!").fontWeight(.medium))
            .font(.system(size: 32))
            .foregroundStyle(.black)
            .multilineTextAlignment(.center)
    }

    private var emojiLayout: [LoginEmojiLayout] {
        [
            .init(asset: "IntroStickerLove", center: .init(x: 346, y: 321), size: 83, rotation: 11.69),
            .init(asset: "LoginEmoji0", center: .init(x: 304.5, y: 382.5), size: 71),
            .init(asset: "LoginEmoji1", center: .init(x: 47, y: 324), size: 83, rotation: -17.4),
            .init(asset: "LoginEmoji2", center: .init(x: 139, y: 276), size: 77.63, rotation: -15.94),
            .init(asset: "LoginEmoji3", center: .init(x: 291.5, y: 487.5), size: 83, rotation: 2.96),
            .init(asset: "LoginEmoji4", center: .init(x: 109.5, y: 494.5), size: 83),
            .init(asset: "LoginEmoji5", center: .init(x: 370.5, y: 432.5), size: 75),
            .init(asset: "LoginEmoji6", center: .init(x: 40.2, y: 426.2), size: 75, rotation: -4.29),
            .init(asset: "LoginEmoji7", center: .init(x: 312.5, y: 240.6), size: 83, rotation: 20.9),
            .init(asset: "IntroStickerLaugh", center: .init(x: 201.5, y: 552), size: 83),
            .init(asset: "IntroStickerCurly", center: .init(x: 93, y: 246), size: 82),
            .init(asset: "LoginEmoji11", center: .init(x: 266.8, y: 271.8), size: 57, rotation: -4.81),
            .init(asset: "LoginEmoji8", center: .init(x: 101.5, y: 391.5), size: 67),
            .init(asset: "LoginEmoji9", center: .init(x: 206.5, y: 470.5), size: 67),
            .init(asset: "LoginEmoji10", center: .init(x: 201.5, y: 226.5), size: 67)
        ]
    }
}

private struct LoginEmojiLayout {
    let asset: String
    let center: CGPoint
    let size: CGFloat
    var rotation: Double = 0
}
