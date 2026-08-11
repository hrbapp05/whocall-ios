import Foundation
import Observation
import RevenueCat

enum RevenueCatProductID: String, CaseIterable, Sendable {
    case premiumWeekly = "com.levelappstudio.whocall.premium.weekly"
    case premiumMonthly = "com.levelappstudio.whocall.premium.monthly"
    case credits3 = "com.levelappstudio.whocall.credits.3"
    case credits5 = "com.levelappstudio.whocall.credits.5"
    case credits10 = "com.levelappstudio.whocall.credits.10"

    static let premium: [Self] = [.premiumWeekly, .premiumMonthly]
    static let credits: [Self] = [.credits3, .credits5, .credits10]

    var creditAmount: Int? {
        switch self {
        case .credits3: 3
        case .credits5: 5
        case .credits10: 10
        default: nil
        }
    }
}

enum RevenueCatConfiguration {
    static let infoPlistKey = "REVENUECAT_PUBLIC_SDK_KEY"

    static func publicSDKKey(in bundle: Bundle = .main) -> String? {
        guard let rawValue = bundle.object(forInfoDictionaryKey: infoPlistKey) as? String else {
            return nil
        }
        let key = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        return isUsablePublicSDKKey(key) ? key : nil
    }

    static func isUsablePublicSDKKey(_ key: String) -> Bool {
        !key.isEmpty &&
        key.count > 8 &&
        !key.contains("$(") &&
        !key.lowercased().contains("replace")
    }
}

@MainActor
@Observable
final class PurchaseStore {
    static let premiumEntitlementID = "premium"
    static let creditBalanceKey = "creditBalance"

    private(set) var isConfigured = false
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var isPremium = false
    private(set) var creditBalance: Int
    private(set) var products: [String: StoreProduct] = [:]
    private(set) var offerings: Offerings?
    var alertMessage: String?

    private var hasStarted = false
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Self.creditBalanceKey) == nil {
            defaults.set(5, forKey: Self.creditBalanceKey)
        }
        creditBalance = defaults.integer(forKey: Self.creditBalanceKey)
    }

    func start() async {
        guard !hasStarted else { return }
        hasStarted = true

        guard let publicSDKKey = RevenueCatConfiguration.publicSDKKey() else {
            return
        }

#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .warn
#endif
        Purchases.configure(withAPIKey: publicSDKKey)
        isConfigured = true

        Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                guard let self else { return }
                self.apply(customerInfo)
            }
        }

        await refreshProducts()
    }

    func refreshProducts() async {
        guard isConfigured else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        async let fetchedOfferings = try? Purchases.shared.offerings()
        let fetchedProducts = await Purchases.shared.products(RevenueCatProductID.allCases.map(\.rawValue))

        products = Dictionary(uniqueKeysWithValues: fetchedProducts.map { ($0.productIdentifier, $0) })
        offerings = await fetchedOfferings
    }

    func localizedPrice(for productID: RevenueCatProductID, fallback: String) -> String {
        products[productID.rawValue]?.localizedPriceString ?? fallback
    }

    @discardableResult
    func purchase(_ productID: RevenueCatProductID) async -> Bool {
        guard ensureConfigured() else { return false }

        if products[productID.rawValue] == nil {
            await refreshProducts()
        }
        guard let product = products[productID.rawValue] else {
            alertMessage = "Ürün mağazadan alınamadı. App Store Connect ürün durumunu ve internet bağlantısını kontrol edin."
            return false
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(product: product)
            guard !userCancelled else { return false }

            apply(customerInfo)
            if let amount = productID.creditAmount {
                addCredits(amount)
                alertMessage = "\(amount) sorgulama kredisi hesabınıza eklendi."
            } else {
                alertMessage = "WhoCall Premium etkinleştirildi."
            }
            return true
        } catch {
            alertMessage = "Satın alma tamamlanamadı: \(error.localizedDescription)"
            return false
        }
    }

    @discardableResult
    func restorePurchases() async -> Bool {
        guard ensureConfigured() else { return false }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            apply(customerInfo)
            alertMessage = isPremium
                ? "Premium aboneliğiniz geri yüklendi."
                : "Geri yüklenecek etkin bir abonelik bulunamadı."
            return isPremium
        } catch {
            alertMessage = "Satın alımlar geri yüklenemedi: \(error.localizedDescription)"
            return false
        }
    }

    func clearAlert() {
        alertMessage = nil
    }

    private func ensureConfigured() -> Bool {
        guard isConfigured else {
            alertMessage = "RevenueCat public SDK anahtarı bu build'e eklenmemiş. Anahtarı REVENUECAT_PUBLIC_SDK_KEY build ayarıyla güvenli biçimde sağlayın."
            return false
        }
        return true
    }

    private func apply(_ customerInfo: CustomerInfo) {
        isPremium = customerInfo.entitlements[Self.premiumEntitlementID]?.isActive == true ||
            !customerInfo.activeSubscriptions.isEmpty
    }

    private func addCredits(_ amount: Int) {
        creditBalance += amount
        defaults.set(creditBalance, forKey: Self.creditBalanceKey)
    }
}
