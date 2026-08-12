import SwiftUI

struct OnboardingHero: View {
    let page: OnboardingPage

    var body: some View {
        ZStack {
            decorativeBackground
                .zIndex(0)

            Image(page.mockupAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 273, height: 561)
                .position(x: 201, y: 446.5)
                .shadow(color: .black.opacity(0.12), radius: 13, y: 7)
                .popEntrance(delay: 0.04, initialScale: 0.84)
                .gentleFloat(distance: 2.5, duration: 3.1)
                .zIndex(1)

            phoneFade
                .allowsHitTesting(false)
                .zIndex(2)

            foregroundContent
                .zIndex(3)
        }
        .frame(width: 402, height: 874)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(page.title.replacingOccurrences(of: "\n", with: " ")))
    }

    private var phoneFade: some View {
        let isDetailsPage = page == .details
        let gradientHeight: CGFloat = isDetailsPage ? 272 : 210
        let totalHeight: CGFloat = isDetailsPage ? 574 : 546
        let centerY: CGFloat = isDetailsPage ? 587 : 601

        return VStack(spacing: 0) {
            LinearGradient(
                stops: isDetailsPage
                    ? [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.18), location: 0.16),
                        .init(color: .white.opacity(0.82), location: 0.58),
                        .init(color: .white, location: 0.86)
                    ]
                    : [
                        .init(color: .clear, location: 0),
                        .init(color: .white.opacity(0.78), location: 0.56),
                        .init(color: .white, location: 1)
                    ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: gradientHeight)

            Color.white
        }
        .frame(width: 402, height: totalHeight)
        .position(x: 201, y: centerY)
    }

    @ViewBuilder
    private var decorativeBackground: some View {
        switch page {
        case .unknownNumbers:
            EmptyView()
        case .scan:
            Circle()
                .fill(DesignTokens.ColorToken.brandBlue.opacity(0.045))
                .overlay(Circle().stroke(DesignTokens.ColorToken.brandBlue.opacity(0.20), lineWidth: 1))
                .frame(width: 344, height: 344)
                .position(x: 201, y: 301)
                .figmaEntrance(delay: 0.05, distance: 0)
        case .details:
            Image("Intro3Decor")
                .resizable()
                .scaledToFit()
                .frame(width: 394, height: 394)
                .position(x: 205, y: 280)
                .figmaEntrance(delay: 0.05, distance: 0)
                .gentleFloat(distance: 3, duration: 2.8)
        }
    }

    @ViewBuilder
    private var foregroundContent: some View {
        switch page {
        case .unknownNumbers:
            sticker(
                "IntroStickerCurly",
                size: 82,
                x: 88,
                y: 175,
                rotation: -11,
                delay: 0
            )
            sticker(
                "IntroStickerLove",
                size: 86,
                x: 330,
                y: 273,
                rotation: 12,
                delay: 0.25
            )
            sticker(
                "IntroStickerLaugh",
                size: 84,
                x: 64,
                y: 371,
                rotation: -16,
                delay: 0.5
            )
            recentCard
                .position(x: 201, y: 501.5)
                .rotationEffect(.degrees(2.1))
                .popEntrance(delay: 0.24, initialScale: 0.74)
                .gentleFloat(distance: 3, duration: 2.5, delay: 0.3)
        case .scan:
            scannerCard
                .position(x: 201, y: 518)
                .popEntrance(delay: 0.24, initialScale: 0.78)
        case .details:
            detailCard
                .position(x: 201, y: 455)
                .popEntrance(delay: 0.22, initialScale: 0.76)
        }
    }

    private func sticker(
        _ name: String,
        size: CGFloat,
        x: CGFloat,
        y: CGFloat,
        rotation: Double,
        delay: Double
    ) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .position(x: x, y: y)
            .gentleFloat(distance: 5, duration: 2.1 + delay, delay: delay)
            .popEntrance(delay: 0.08 + delay / 3, initialScale: 0.05)
    }

    private var recentCard: some View {
        HStack(spacing: 10) {
            Text("T")
                .font(.caption.weight(.bold))
                .frame(width: 50, height: 50)
                .background(DesignTokens.ColorToken.mint, in: .circle)
            VStack(alignment: .leading, spacing: 5) {
                Text("+61 (452) 779-603").font(.caption).foregroundStyle(.secondary)
                Text("Tarık H. Olarak Biliniyor").font(.subheadline.weight(.bold))
            }
            Spacer()
            Text("16:35").font(.caption).foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 346, height: 98)
        .background(.white, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 30, y: 10)
    }

    private var scannerCard: some View {
        VStack(spacing: 0) {
            scanRow("Numara Doğrulandı", symbol: "checkmark", active: true)
            Divider()
            scanRow("Kayıtlar Taranıyor", symbol: "circle.dotted", active: true)
            Divider()
            scanRow("Sonuç Hazırlanıyor", symbol: "circle", active: false)
        }
        .padding(.horizontal, 16)
        .frame(width: 344, height: 126)
        .background(.white, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 10)
    }

    private func scanRow(_ title: String, symbol: String, active: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundStyle(active ? DesignTokens.ColorToken.brandBlue : .primary)
            Text(title).font(.caption.weight(.medium))
            Spacer()
        }
        .frame(height: 40)
    }

    private var detailCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Güven Seviyesi")
                Spacer()
                Text("Yüksek").foregroundStyle(DesignTokens.ColorToken.success)
                Image(systemName: "checkmark.shield.fill").foregroundStyle(DesignTokens.ColorToken.success)
            }
            detailDivider
            HStack { Label("Topluluk Yorumları", systemImage: "bubble.left"); Spacer(); Text("12") }
            detailDivider
            HStack {
                Label("Etiketler", systemImage: "number")
                Spacer()
                FigmaTag(title: "Komşu")
                FigmaTag(title: "Kankam")
                FigmaTag(title: "Tesisatçı")
            }
            detailDivider
            HStack { Label("Yorum Ekle", systemImage: "square.and.pencil"); Spacer(); Image(systemName: "chevron.right") }
        }
        .font(.caption)
        .padding(.horizontal, 16)
        .frame(width: 362, height: 170)
        .background(.white, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.10), radius: 28, y: 10)
    }

    private var detailDivider: some View {
        Divider().padding(.vertical, 8)
    }
}
