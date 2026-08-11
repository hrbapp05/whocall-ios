import SwiftUI

struct OnboardingHero: View {
    let page: OnboardingPage

    var body: some View {
        ZStack(alignment: .center) {
            if page == .scan {
                Circle()
                    .fill(DesignTokens.ColorToken.brandBlue.opacity(0.045))
                    .overlay(Circle().stroke(DesignTokens.ColorToken.brandBlue.opacity(0.20), lineWidth: 1))
                    .frame(width: 344, height: 344)
                    .offset(y: -22)
                    .figmaEntrance(delay: 0.05, distance: 0)
            }

            if page == .details {
                Image("CreditHero")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 390, height: 390)
                    .offset(y: -56)
                    .gentleFloat(distance: 5, duration: 2.6)
            }

            Image(page.mockupAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 267)
                .offset(y: 76)
                .shadow(color: .black.opacity(0.16), radius: 8, y: 5)
                .figmaEntrance(delay: 0.02, distance: 22)

            if page == .unknownNumbers {
                sticker("IntroStickerLove", size: 82, x: -118, y: -122, rotation: -11, delay: 0)
                sticker("IntroStickerLaugh", size: 86, x: 132, y: -42, rotation: 12, delay: 0.25)
                sticker("IntroStickerCurly", size: 84, x: -128, y: 70, rotation: -16, delay: 0.5)
                recentCard
                    .offset(y: 145)
                    .rotationEffect(.degrees(2.1))
                    .figmaEntrance(delay: 0.22, distance: 24)
                    .gentleFloat(distance: 3, duration: 2.5, delay: 0.3)
                    .zIndex(3)
            } else if page == .scan {
                scannerCard
                    .offset(y: 129)
                    .figmaEntrance(delay: 0.22, distance: 20)
                    .zIndex(3)
            } else {
                detailCard
                    .offset(y: 123)
                    .figmaEntrance(delay: 0.2, distance: 24)
                    .zIndex(3)
            }

            LinearGradient(
                colors: [.clear, .white.opacity(0.82), .white],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 180)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .allowsHitTesting(false)
            .zIndex(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(page.title.replacingOccurrences(of: "\n", with: " ")))
    }

    private func sticker(_ name: String, size: CGFloat, x: CGFloat, y: CGFloat, rotation: Double, delay: Double) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .rotationEffect(.degrees(rotation))
            .offset(x: x, y: y)
            .gentleFloat(distance: 5, duration: 2.1 + delay, delay: delay)
            .figmaEntrance(delay: 0.08 + delay / 3, distance: 12)
            .zIndex(3)
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
