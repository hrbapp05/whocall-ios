import SwiftUI

enum PurchasePaywallSection: String, CaseIterable, Identifiable {
    case subscriptions
    case credits

    var id: Self { self }

    var title: String {
        switch self {
        case .subscriptions: "Abonelikler"
        case .credits: "Krediler"
        }
    }
}

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseStore.self) private var purchaseStore
    @State private var selectedPlan = 1
    @State private var selectedCredit = 5
    @State private var selectedSection: PurchasePaywallSection
    @State private var showsCloseButton = false
    @State private var hasTrackedPresentation = false
    @Namespace private var sectionPickerAnimation

    private let closeDelayMilliseconds: Int
    private let onClose: (() -> Void)?

    init(
        initialSection: PurchasePaywallSection = .subscriptions,
        closeDelayMilliseconds: Int = 0,
        onClose: (() -> Void)? = nil
    ) {
        _selectedSection = State(initialValue: initialSection)
        self.closeDelayMilliseconds = closeDelayMilliseconds
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                paywallHero

                sectionPicker
                    .padding(.horizontal, 44)
                    .padding(.top, 2)
                    .padding(.bottom, 2)

                Group {
                    switch selectedSection {
                    case .subscriptions:
                        subscriptionContent
                    case .credits:
                        creditContent
                    }
                }
                .id(selectedSection)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
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
            if !hasTrackedPresentation {
                hasTrackedPresentation = true
                MetaAttributionService.shared.trackPaywallPresented(section: selectedSection.rawValue)
            }
            guard !showsCloseButton else { return }
            if closeDelayMilliseconds > 0 {
                try? await Task.sleep(for: .milliseconds(closeDelayMilliseconds))
            }
            withAnimation(.spring(duration: 0.42, bounce: 0.28)) {
                showsCloseButton = true
            }
        }
        .onChange(of: selectedSection) { _, section in
            MetaAttributionService.shared.trackPaywallPresented(section: section.rawValue)
        }
    }

    private func close() {
        MetaAttributionService.shared.trackPaywallDismissed(section: selectedSection.rawValue)
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private var selectedProductID: RevenueCatProductID {
        if selectedSection == .credits { return selectedCreditProductID }
        return selectedPlan == 0 ? .premiumWeekly : .premiumMonthly
    }

    private var selectedCreditProductID: RevenueCatProductID {
        switch selectedCredit {
        case 3: .credits3
        case 10: .credits10
        default: .credits5
        }
    }

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(PurchasePaywallSection.allCases) { section in
                Button {
                    withAnimation(.spring(duration: 0.38, bounce: 0.18)) {
                        selectedSection = section
                    }
                } label: {
                    Text(section.title)
                        .font(.subheadline.weight(selectedSection == section ? .semibold : .regular))
                        .foregroundStyle(selectedSection == section ? .white : .secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selectedSection == section {
                                Capsule()
                                    .fill(DesignTokens.ColorToken.brandBlue)
                                    .matchedGeometryEffect(id: "purchase-section", in: sectionPickerAnimation)
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedSection == section ? .isSelected : [])
            }
        }
        .padding(4)
        .background(DesignTokens.ColorToken.brandBlue.opacity(0.07), in: .capsule)
        .overlay {
            Capsule()
                .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.08), lineWidth: 1)
        }
        .frame(maxWidth: 284)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Satın alma türü")
        .accessibilityHint("Abonelik ve kredi seçenekleri arasında geçiş yapar")
    }

    @ViewBuilder
    private var paywallHero: some View {
        switch selectedSection {
        case .subscriptions:
            premiumHero
                .figmaEntrance(delay: 0.04, distance: 10)
        case .credits:
            creditHero
                .figmaEntrance(delay: 0.04, distance: 10)
        }
    }

    private var subscriptionContent: some View {
        VStack(spacing: 0) {
            Text("Premium ol")
                .font(.subheadline)
                .padding(.top, 12)
            HStack(spacing: 4) {
                Text("Daha Fazlasını")
                Text("Keşfet!").foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .font(.title3.weight(.bold))
            .padding(.top, 2)
            Text("WhoCall Premium ile tüm bilgilerin kilidini açın.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 3)

            benefits.padding(.top, 12)

            VStack(spacing: 10) {
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
            .padding(.horizontal, 20)
            .padding(.top, 14)

            purchaseActions
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 16)
        }
    }

    private var creditContent: some View {
        VStack(spacing: 0) {
            Text("Sorgular için").font(.subheadline).padding(.top, 12)
            HStack(spacing: 4) {
                Text("Kredi")
                Text("Satın Al").foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .font(.title3.weight(.bold))
            .padding(.top, 2)
            Text("Abonelik gerektirmeden sorguların için kredi alabilirsin.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.top, 3)

            VStack(spacing: 10) {
                creditOption(3, price: purchaseStore.localizedPrice(for: .credits3, fallback: "199,99"))
                creditOption(5, price: purchaseStore.localizedPrice(for: .credits5, fallback: "249,99"))
                creditOption(10, price: purchaseStore.localizedPrice(for: .credits10, fallback: "499,99"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            purchaseActions
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 16)
        }
    }

    private var purchaseActions: some View {
        VStack(spacing: 14) {
            Button {
                let productID = selectedProductID
                MetaAttributionService.shared.trackCheckoutStarted(
                    productID: productID.rawValue,
                    productType: selectedSection == .subscriptions ? "subscription" : "credits"
                )
                Task { await purchaseStore.purchase(productID) }
            } label: {
                if purchaseStore.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(selectedSection == .subscriptions ? "Premium’a Geç" : "Kredi Satın Al")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(purchaseStore.isPurchasing)

            HStack(spacing: 10) {
                Link("Abonelik Koşulları", destination: LegalPolicy.termsOfUseURL)
                Text("•")
                Link("Gizlilik Politikası", destination: LegalPolicy.privacyPolicyURL)
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
                .frame(width: 146, height: 146)
            Circle()
                .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.35), lineWidth: 1)
                .frame(width: 84, height: 84)
            Image("PremiumHero")
                .resizable().scaledToFit().frame(width: 78, height: 78)
                .shadow(color: DesignTokens.ColorToken.brandBlue.opacity(0.25), radius: 16, y: 8)
                .gentleFloat(distance: 4, duration: 2.5)
            paywallEmoji("IntroStickerLove", size: 43, x: -73, y: -34, delay: 0)
            paywallEmoji("LoginEmoji4", size: 43, x: 74, y: -38, delay: 0.2)
            paywallEmoji("IntroStickerCurly", size: 45, x: -54, y: 58, delay: 0.4)
            paywallEmoji("IntroStickerLaugh", size: 45, x: 65, y: 51, delay: 0.6)
        }
        .frame(height: 152)
    }

    private var creditHero: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.ColorToken.brandBlue.opacity(0.045))
                .overlay(Circle().stroke(DesignTokens.ColorToken.brandBlue.opacity(0.2), lineWidth: 1))
                .frame(width: 146, height: 146)
            Image("CreditHero")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .gentleFloat(distance: 4, duration: 2.6)
        }
        .frame(height: 152)
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
                .frame(width: 30, height: 32)
                .background(DesignTokens.ColorToken.brandBlue, in: .rect(cornerRadius: 7))
            Text(title).font(.caption.weight(.medium)).lineLimit(1)
        }
        .padding(.horizontal, 10)
        .frame(height: 46)
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
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: index == 1 ? 80 : 68)
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

    private func creditOption(_ amount: Int, price: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.18)) { selectedCredit = amount }
        } label: {
            HStack(spacing: 8) {
                Image("CreditGlyph").resizable().scaledToFit().frame(width: 26, height: 26)
                Text("\(amount)").font(.title.weight(.bold))
                Spacer()
                Text(price).font(.subheadline.weight(.semibold))
                Image(systemName: selectedCredit == amount ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .padding(.horizontal, 16)
            .frame(height: 62)
            .background(.white, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selectedCredit == amount ? DesignTokens.ColorToken.brandBlue : .clear, lineWidth: 2)
            }
            .overlay(alignment: .top) {
                if amount == 5 {
                    Text("En Popüler")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(DesignTokens.ColorToken.brandBlue, in: .capsule)
                        .offset(y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
