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
    static let creditBalanceMigrationKey = "creditBalance.v2.initialized"
    static let processedCreditTransactionsKey = "whocall.processedCreditTransactions.v1"

    private(set) var isConfigured = false
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var isPremium = false
    private(set) var creditBalance: Int
    private(set) var products: [String: StoreProduct] = [:]
    private(set) var offerings: Offerings?
    var alertMessage: String?

    private var hasStarted = false
    private var activeAccountID: String?
    private var revenueCatAccountID: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if !defaults.bool(forKey: Self.creditBalanceMigrationKey) {
            // Earlier test builds displayed five placeholder credits. They were never
            // purchased. Preserve every other balance because it may include a real
            // consumable purchase from a previous TestFlight build.
            let previousBalance = defaults.object(forKey: Self.creditBalanceKey) == nil
                ? 0
                : defaults.integer(forKey: Self.creditBalanceKey)
            defaults.set(previousBalance == 5 ? 0 : previousBalance, forKey: Self.creditBalanceKey)
            defaults.set(true, forKey: Self.creditBalanceMigrationKey)
        }
        creditBalance = defaults.integer(forKey: Self.creditBalanceKey)
    }

    func start(accountID: String? = nil) async {
        switchLocalAccount(to: accountID)
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

        await synchronizeRevenueCatAccount()

        Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                guard let self else { return }
                self.apply(customerInfo)
            }
        }

        if let customerInfo = try? await Purchases.shared.customerInfo() {
            apply(customerInfo)
        }
        await refreshProducts()
    }

    /// Firebase UID is a stable, non-PII identifier linked to the verified phone
    /// account. It keeps entitlements and local consumable credits separate when
    /// multiple people use the same device.
    func activateAccount(_ accountID: String?) async {
        switchLocalAccount(to: accountID)
        guard isConfigured else { return }
        await synchronizeRevenueCatAccount()
    }

    var hasLookupAccess: Bool {
        isPremium || creditBalance > 0
    }

    /// Premium includes unlimited lookups. Otherwise one purchased credit is
    /// consumed immediately before the result is revealed.
    @discardableResult
    func authorizeLookupResult() -> Bool {
        if isPremium { return true }
        guard creditBalance > 0 else { return false }
        creditBalance -= 1
        defaults.set(creditBalance, forKey: creditStorageKey)
        return true
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
            let (transaction, customerInfo, userCancelled) = try await Purchases.shared.purchase(product: product)
            guard !userCancelled else { return false }

            apply(customerInfo)
            if let amount = productID.creditAmount {
                guard let transactionID = transaction?.transactionIdentifier else {
                    alertMessage = "Kredi işlemi doğrulanamadı. Satın alım geçmişinizi yenileyip tekrar deneyin."
                    return false
                }
                if grantCreditsOnce(amount, transactionID: transactionID) {
                    alertMessage = "\(amount) sorgulama kredisi hesabınıza eklendi."
                } else {
                    alertMessage = "Bu kredi işlemi daha önce hesabınıza eklenmiş."
                }
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

    private func switchLocalAccount(to accountID: String?) {
        guard activeAccountID != accountID else { return }
        activeAccountID = accountID
        creditBalance = defaults.integer(forKey: creditStorageKey)
    }

#if DEBUG
    func switchAccountForTesting(_ accountID: String?) {
        switchLocalAccount(to: accountID)
    }
#endif

    private func synchronizeRevenueCatAccount() async {
        do {
            if let activeAccountID {
                guard revenueCatAccountID != activeAccountID else { return }
                let result = try await Purchases.shared.logIn(activeAccountID)
                revenueCatAccountID = activeAccountID
                apply(result.customerInfo)
            } else if revenueCatAccountID != nil {
                let customerInfo = try await Purchases.shared.logOut()
                revenueCatAccountID = nil
                apply(customerInfo)
            } else {
                isPremium = false
            }
        } catch {
            alertMessage = "Satın alma hesabı güncellenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin."
        }
    }

    private var creditStorageKey: String {
        guard let activeAccountID else { return Self.creditBalanceKey }
        return "\(Self.creditBalanceKey).account.\(activeAccountID)"
    }

    private var processedTransactionsStorageKey: String {
        guard let activeAccountID else { return Self.processedCreditTransactionsKey }
        return "\(Self.processedCreditTransactionsKey).account.\(activeAccountID)"
    }

    @discardableResult
    private func grantCreditsOnce(_ amount: Int, transactionID: String) -> Bool {
        var processedTransactions = Set(
            defaults.stringArray(forKey: processedTransactionsStorageKey) ?? []
        )
        guard processedTransactions.insert(transactionID).inserted else { return false }
        creditBalance += amount
        defaults.set(creditBalance, forKey: creditStorageKey)
        defaults.set(Array(processedTransactions), forKey: processedTransactionsStorageKey)
        return true
    }
}
