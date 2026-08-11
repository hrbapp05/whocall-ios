import SwiftUI

struct OnboardingHero: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            if page == .scan {
                Circle()
                    .fill(Color.blue.opacity(0.08))
                    .overlay(Circle().stroke(Color.blue.opacity(0.16), lineWidth: 1))
                    .frame(width: 342, height: 342)
            }

            Image(page.heroAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 265, height: 338)
                .clipShape(.rect(cornerRadius: DesignTokens.Radius.device))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignTokens.Radius.device)
                        .stroke(.black, lineWidth: 5)
                }
                .shadow(color: .black.opacity(0.12), radius: 8, y: 5)

            if page == .unknownNumbers {
                sticker("IntroStickerCurly", size: 74, x: -135, y: 38, rotation: -16)
                sticker("IntroStickerLove", size: 78, x: -112, y: -145, rotation: -11)
                sticker("IntroStickerLaugh", size: 82, x: 130, y: -65, rotation: 12)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 365)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(page.title.replacingOccurrences(of: "\n", with: " ")))
    }

    private func sticker(_ name: String, size: CGFloat, x: CGFloat, y: CGFloat, rotation: Double) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
    }
}

