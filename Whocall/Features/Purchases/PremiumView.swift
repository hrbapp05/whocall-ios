import SwiftUI

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseStore.self) private var purchaseStore
    @State private var selectedPlan = 1
    @State private var showsCloseButton = false

    private let closeDelayMilliseconds: Int
    private let onClose: (() -> Void)?

    init(
        closeDelayMilliseconds: Int = 0,
        onClose: (() -> Void)? = nil
    ) {
        self.closeDelayMilliseconds = closeDelayMilliseconds
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                premiumHero
                    .padding(.top, -28)
                    .figmaEntrance(delay: 0.04, distance: 14)

                Text("Premium ol")
                    .font(.body)
                    .padding(.top, 8)
                HStack(spacing: 4) {
                    Text("Daha Fazlasını")
                    Text("Keşfet!").foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }
                .font(.title2.weight(.bold))
                .padding(.top, 4)
                Text("WhoCall Premium ile tüm bilgilerin kilidini açın.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                benefits
                    .padding(.top, 22)

                VStack(spacing: 16) {
                    plan(
                        0,
                        "Haftalık Premium",
                        subtitle: "Haftalık Tam Erişim",
                        price: purchaseStore.localizedPrice(for: .premiumWeekly, fallback: "499,99"),
                        suffix: "/hafta"
                    )
                    plan(
                        1,
                        "Aylık Premium",
                        subtitle: "Aylık Tam Erişim",
                        price: purchaseStore.localizedPrice(for: .premiumMonthly, fallback: "999,99"),
                        suffix: "/ay"
                    )
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)

                purchaseActions
                    .padding(.horizontal, 20)
                    .padding(.top, 28)
                    .padding(.bottom, 34)
            }
        }
        .background(Color(red: 0.97, green: 0.98, blue: 1).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if showsCloseButton {
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.92), in: .circle)
                    }
                    .tint(.primary)
                    .transition(.scale(scale: 0.25).combined(with: .opacity))
                    .accessibilityLabel("Premium ekranını kapat")
                }
            }
            ToolbarItem(placement: .principal) {
                Image("WhoCallLogo").resizable().scaledToFit().frame(width: 98, height: 20)
            }
            ToolbarItem(placement: .topBarTrailing) { ToolbarCreditBadge() }
        }
        .alert("Satın Alma", isPresented: purchaseAlertPresented) {
            Button("Tamam") { purchaseStore.clearAlert() }
        } message: {
            Text(purchaseStore.alertMessage ?? "")
        }
        .interactiveDismissDisabled(!showsCloseButton)
        .task {
            guard !showsCloseButton else { return }
            if closeDelayMilliseconds > 0 {
                try? await Task.sleep(for: .milliseconds(closeDelayMilliseconds))
            }
            withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                showsCloseButton = true
            }
        }
    }

    private func close() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var selectedProductID: RevenueCatProductID {
        selectedPlan == 0 ? .premiumWeekly : .premiumMonthly
    }

    private var purchaseActions: some View {
        VStack(spacing: 14) {
            Button {
                Task { await purchaseStore.purchase(selectedProductID) }
            } label: {
                if purchaseStore.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text("Premium’a Geç")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(purchaseStore.isPurchasing)

            HStack(spacing: 10) {
                Link("Abonelik Koşulları", destination: URL(string: "https://whocallapp.online")!)
                Text("•")
                Link("Gizlilik Politikası", destination: URL(string: "https://whocallapp.online")!)
                Text("•")
                Button("Geri Yükle") {
                    Task { await purchaseStore.restorePurchases() }
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }

    private var purchaseAlertPresented: Binding<Bool> {
        Binding(
            get: { purchaseStore.alertMessage != nil },
            set: { if !$0 { purchaseStore.clearAlert() } }
        )
    }

    private var premiumHero: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.ColorToken.brandBlue.opacity(0.045))
                .overlay(Circle().stroke(DesignTokens.ColorToken.brandBlue.opacity(0.2), lineWidth: 1))
                .frame(width: 210, height: 210)
            Circle()
                .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.35), lineWidth: 1)
                .frame(width: 118, height: 118)
            Image("PremiumHero")
                .resizable().scaledToFit().frame(width: 108, height: 108)
                .shadow(color: DesignTokens.ColorToken.brandBlue.opacity(0.25), radius: 22, y: 10)
                .gentleFloat(distance: 5, duration: 2.5)
            paywallEmoji("IntroStickerLove", size: 60, x: -102, y: -49, delay: 0)
            paywallEmoji("LoginEmoji4", size: 60, x: 103, y: -54, delay: 0.2)
            paywallEmoji("IntroStickerCurly", size: 62, x: -75, y: 86, delay: 0.4)
            paywallEmoji("IntroStickerLaugh", size: 62, x: 91, y: 73, delay: 0.6)
        }
        .frame(height: 204)
    }

    private func paywallEmoji(_ name: String, size: CGFloat, x: CGFloat, y: CGFloat, delay: Double) -> some View {
        Image(name).resizable().scaledToFit().frame(width: size, height: size)
            .offset(x: x, y: y)
            .gentleFloat(distance: 4, duration: 2.1 + delay, delay: delay)
    }

    private var benefits: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                benefit("Güven Seviyesini Görüntüle")
                benefit("Tüm özelliklere sınırsız erişim")
                benefit("Kişi adı ve etiketleri görüntüle")
            }
            .padding(.horizontal, 18)
        }
    }

    private func benefit(_ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 36)
                .background(DesignTokens.ColorToken.brandBlue, in: .rect(cornerRadius: 7))
            Text(title).font(.caption.weight(.medium)).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 54)
        .background(.white, in: .rect(cornerRadius: 12))
    }

    private func plan(_ index: Int, _ title: String, subtitle: String, price: String, suffix: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.18)) { selectedPlan = index }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.subheadline.weight(.semibold))
                    Text(subtitle).font(.caption)
                    if index == 1 {
                        Text("%25 tasarruf et")
                            .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                            .padding(.horizontal, 12).padding(.vertical, 4)
                            .background(DesignTokens.ColorToken.brandBlue, in: .capsule)
                    }
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(price).font(.subheadline.weight(.bold))
                    Text(suffix).font(.caption)
                }
                Image(systemName: selectedPlan == index ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .padding(16)
            .frame(minHeight: index == 1 ? 90 : 78)
            .background(.white, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedPlan == index ? DesignTokens.ColorToken.brandBlue : .clear, lineWidth: 2)
            }
            .overlay(alignment: .top) {
                if index == 1 {
                    Text("En Popüler")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(DesignTokens.ColorToken.brandBlue, in: .capsule)
                        .offset(y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
