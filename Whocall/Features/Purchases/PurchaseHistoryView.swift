import SwiftUI

struct SubscriptionHistoryView: View {
    @Environment(PurchaseStore.self) private var purchaseStore
    @Environment(\.openURL) private var openURL

    var body: some View {
        List {
            if purchaseStore.subscriptionHistory.isEmpty {
                ContentUnavailableView(
                    "Abonelik bulunamadı",
                    systemImage: "crown",
                    description: Text("Bu hesapla yapılmış bir premium aboneliği görünmüyor.")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(purchaseStore.subscriptionHistory) { subscription in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Label(subscription.title, systemImage: "crown.fill")
                                .font(.headline)
                            Spacer()
                            Text(subscription.isActive ? "Aktif" : "Sona erdi")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(subscription.isActive ? DesignTokens.ColorToken.success : .secondary)
                        }
                        purchaseRow("Başlangıç", date: subscription.purchaseDate)
                        if let expirationDate = subscription.expirationDate {
                            purchaseRow(subscription.isActive ? "Yenilenme/Bitiş" : "Bitiş", date: expirationDate)
                            if subscription.isActive {
                                Text(remainingText(until: expirationDate))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                            }
                        }
                        if subscription.isActive {
                            Label(
                                subscription.willRenew ? "Otomatik yenileme açık" : "Dönem sonunda sona erecek",
                                systemImage: subscription.willRenew ? "arrow.triangle.2.circlepath" : "calendar.badge.exclamationmark"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }

            Section {
                if let managementURL = purchaseStore.subscriptionManagementURL {
                    Button("App Store’da Aboneliği Yönet") { openURL(managementURL) }
                }
                Button("Satın Alımları Geri Yükle") {
                    Task { await purchaseStore.restorePurchases() }
                }
            }
        }
        .navigationTitle("Aboneliklerim")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await purchaseStore.refreshCustomerInfo() }
        .task { await purchaseStore.refreshCustomerInfo() }
    }

    private func purchaseRow(_ title: String, date: Date) -> some View {
        HStack {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(date.formatted(date: .abbreviated, time: .omitted))
        }
        .font(.subheadline)
    }

    private func remainingText(until date: Date) -> String {
        let days = max(0, Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0)
        if days == 0 { return "Bugün sona eriyor" }
        return "\(days) gün kaldı"
    }
}

struct CreditPurchaseHistoryView: View {
    @Environment(PurchaseStore.self) private var purchaseStore

    var body: some View {
        List {
            Section {
                HStack {
                    Label("Kalan kredi", systemImage: "creditcard.fill")
                    Spacer()
                    Text("\(purchaseStore.creditBalance)")
                        .font(.title3.bold())
                        .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }
            }

            if purchaseStore.creditPurchaseHistory.isEmpty {
                ContentUnavailableView(
                    "Kredi alımı bulunamadı",
                    systemImage: "creditcard",
                    description: Text("Bu hesapla yapılmış bir kredi satın alımı görünmüyor.")
                )
                .listRowBackground(Color.clear)
            } else {
                Section("Satın Alma Geçmişi") {
                    ForEach(purchaseStore.creditPurchaseHistory) { purchase in
                        HStack(spacing: 12) {
                            Image("CreditGlyph")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(purchase.title).font(.headline)
                                Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("+\(purchase.creditAmount)")
                                .font(.headline)
                                .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Kredi Alımlarım")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await purchaseStore.refreshCustomerInfo() }
        .task { await purchaseStore.refreshCustomerInfo() }
    }
}
