import Foundation
import Observation
import RevenueCat
import StoreKit

#if canImport(FirebaseFunctions)
@preconcurrency import FirebaseFunctions
import FirebaseCore
#endif

enum RevenueCatProductID: String, CaseIterable, Sendable {
    case premiumWeekly = "com.levelappstudio.whocall.premium.weekly"
    case premiumMonthly = "com.levelappstudio.whocall.premium.monthly"
    case credits3 = "com.levelappstudio.whocall.credits.3"
    case credits5 = "com.levelappstudio.whocall.credits.5"
    case credits10 = "com.levelappstudio.whocall.credits.10"

    static let premium: [Self] = [.premiumWeekly, .premiumMonthly]
    static let credits: [Self] = [.credits3, .credits5, .credits10]

    static func unlocksPremium(productIdentifier: String) -> Bool {
        premium.contains { $0.rawValue == productIdentifier }
    }

    var creditAmount: Int? {
        switch self {
        case .credits3: 3
        case .credits5: 5
        case .credits10: 10
        default: nil
        }
    }

    var displayName: String {
        switch self {
        case .premiumWeekly: "Haftalık Premium"
        case .premiumMonthly: "Aylık Premium"
        case .credits3: "3 Sorgulama Kredisi"
        case .credits5: "5 Sorgulama Kredisi"
        case .credits10: "10 Sorgulama Kredisi"
        }
    }
}

struct SubscriptionPurchaseRecord: Identifiable, Equatable, Sendable {
    let productID: String
    let title: String
    let purchaseDate: Date
    let expirationDate: Date?
    let isActive: Bool
    let willRenew: Bool

    var id: String { productID }
}

struct CreditPurchaseRecord: Identifiable, Equatable, Sendable {
    let id: String
    let productID: String
    let title: String
    let creditAmount: Int
    let purchaseDate: Date
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
    static let pendingSignedCreditTransactionsKey = "whocall.pendingSignedCreditTransactions.v1"

    private(set) var isConfigured = false
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var revenueCatPremium = false
    private(set) var promotionalPremium = false
    private(set) var promotionalPremiumExpiresAt: Date?
    private(set) var showPostLoginPaywall = true
    private(set) var purchasedCreditBalance: Int
    private(set) var promotionalCreditBalance = 0
    private(set) var products: [String: StoreProduct] = [:]
    private(set) var offerings: Offerings?
    private(set) var subscriptionHistory: [SubscriptionPurchaseRecord] = []
    private(set) var creditPurchaseHistory: [CreditPurchaseRecord] = []
    private(set) var subscriptionManagementURL: URL?
    var alertMessage: String?

    private var hasStarted = false
    private var activeAccountID: String?
    private var revenueCatAccountID: String?
    private let defaults: UserDefaults

#if canImport(FirebaseFunctions)
    private let functions = Functions.functions(region: "europe-west1")
#endif

    var isPremium: Bool {
        if revenueCatPremium { return true }
        guard promotionalPremium else { return false }
        return promotionalPremiumExpiresAt.map { $0 > Date() } ?? true
    }

    var creditBalance: Int {
        purchasedCreditBalance + promotionalCreditBalance
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Credit balances are account-scoped and server-managed. UserDefaults is
        // intentionally not a balance source because it disappears on reinstall.
        purchasedCreditBalance = 0
    }

    func start(accountID: String? = nil) async {
        switchLocalAccount(to: accountID)
        guard !hasStarted else { return }
        hasStarted = true

        await refreshPromotionalAccess()
        await retryPendingCreditClaims()

        guard let publicSDKKey = RevenueCatConfiguration.publicSDKKey() else {
            await syncPurchaseSnapshot()
            return
        }

#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .warn
#endif
        Purchases.configure(withAPIKey: publicSDKKey)
        isConfigured = true
        MetaAttributionService.shared.revenueCatDidConfigure()

        await synchronizeRevenueCatAccount()

        Task { [weak self] in
            for await customerInfo in Purchases.shared.customerInfoStream {
                guard let self else { return }
                self.apply(customerInfo)
                await self.syncPurchaseSnapshot()
            }
        }

        if let customerInfo = try? await Purchases.shared.customerInfo() {
            apply(customerInfo)
        }
        await refreshProducts()
        await syncPurchaseSnapshot()
    }

    /// Firebase UID is a stable, non-PII identifier linked to the verified phone
    /// account. It keeps entitlements and local consumable credits separate when
    /// multiple people use the same device.
    func activateAccount(_ accountID: String?) async {
        switchLocalAccount(to: accountID)
        await refreshPromotionalAccess()
        await retryPendingCreditClaims()
        if isConfigured { await synchronizeRevenueCatAccount() }
        await syncPurchaseSnapshot()
    }

    var hasLookupAccess: Bool {
        isPremium || creditBalance > 0
    }

    /// Premium includes unlimited lookups. Otherwise the server atomically
    /// consumes one account-scoped credit before the result is revealed.
    @discardableResult
    func authorizeLookupResult() async -> Bool {
        if isPremium { return true }
        return await consumeServerCredit()
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

    func refreshCustomerInfo() async {
        await refreshPromotionalAccess()
        if isConfigured {
            do {
                apply(try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent))
            } catch {
                alertMessage = "Satın alma bilgileri yenilenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin."
            }
        }
        await syncPurchaseSnapshot()
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
                guard let transaction,
                      let signedTransaction = await signedTransactionJWS(
                        for: productID,
                        storeTransaction: transaction
                      ) else {
                    alertMessage = "Kredi işlemi doğrulanamadı. Satın alım geçmişinizi yenileyip tekrar deneyin."
                    return false
                }
                enqueuePendingCreditClaim(signedTransaction)
                guard let result = await claimPurchasedCredits(signedTransaction) else {
                    alertMessage = "Satın alımınız alındı ancak kredi sunucuyla eşitlenemedi. İnternet bağlantısı geldiğinde otomatik olarak tekrar denenecek."
                    return false
                }
                removePendingCreditClaim(signedTransaction)
                if result.creditedAmount > 0 {
                    alertMessage = "\(amount) sorgulama kredisi hesabınıza eklendi."
                } else {
                    alertMessage = "Bu kredi işlemi daha önce hesabınıza eklenmiş."
                }
            } else {
                alertMessage = "WhoCall Premium etkinleştirildi."
            }
            await syncPurchaseSnapshot()
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
            await syncPurchaseSnapshot()
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

    func clearLocalAccountData(accountID: String) async {
        defaults.removeObject(forKey: "\(Self.creditBalanceKey).account.\(accountID)")
        defaults.removeObject(forKey: "\(Self.processedCreditTransactionsKey).account.\(accountID)")
        defaults.removeObject(forKey: "\(Self.pendingSignedCreditTransactionsKey).account.\(accountID)")

        if isConfigured, revenueCatAccountID != nil {
            _ = try? await Purchases.shared.logOut()
        }

        activeAccountID = nil
        revenueCatAccountID = nil
        revenueCatPremium = false
        promotionalPremium = false
        promotionalPremiumExpiresAt = nil
        purchasedCreditBalance = 0
        promotionalCreditBalance = 0
        subscriptionHistory = []
        creditPurchaseHistory = []
        subscriptionManagementURL = nil
    }

    private func ensureConfigured() -> Bool {
        guard isConfigured else {
            alertMessage = "RevenueCat public SDK anahtarı bu build'e eklenmemiş. Anahtarı REVENUECAT_PUBLIC_SDK_KEY build ayarıyla güvenli biçimde sağlayın."
            return false
        }
        return true
    }

    private func apply(_ customerInfo: CustomerInfo) {
        // RevenueCat can expose a mistakenly attached entitlement for a consumable.
        // Unlimited access is therefore valid only when the active entitlement was
        // granted by one of WhoCall's weekly/monthly subscription products.
        if let entitlement = customerInfo.entitlements[Self.premiumEntitlementID] {
            revenueCatPremium = entitlement.isActive && RevenueCatProductID.unlocksPremium(
                productIdentifier: entitlement.productIdentifier
            )
        } else {
            revenueCatPremium = false
        }
        subscriptionManagementURL = customerInfo.managementURL

        subscriptionHistory = customerInfo.subscriptionsByProductIdentifier.values
            .compactMap { subscription in
                guard let product = RevenueCatProductID(rawValue: subscription.productIdentifier),
                      RevenueCatProductID.premium.contains(product) else { return nil }
                return SubscriptionPurchaseRecord(
                    productID: product.rawValue,
                    title: product.displayName,
                    purchaseDate: subscription.originalPurchaseDate ?? subscription.purchaseDate,
                    expirationDate: subscription.expiresDate,
                    isActive: subscription.isActive,
                    willRenew: subscription.willRenew
                )
            }
            .sorted { $0.purchaseDate > $1.purchaseDate }

        creditPurchaseHistory = customerInfo.nonSubscriptions
            .compactMap { transaction in
                guard let product = RevenueCatProductID(rawValue: transaction.productIdentifier),
                      let amount = product.creditAmount else { return nil }
                return CreditPurchaseRecord(
                    id: transaction.transactionIdentifier,
                    productID: product.rawValue,
                    title: product.displayName,
                    creditAmount: amount,
                    purchaseDate: transaction.purchaseDate
                )
            }
            .sorted { $0.purchaseDate > $1.purchaseDate }
    }

    private func switchLocalAccount(to accountID: String?) {
        guard activeAccountID != accountID else { return }
        activeAccountID = accountID
        purchasedCreditBalance = 0
        // Never carry server-managed access from the previous verified account
        // while the new account's callable refresh is still in flight or offline.
        promotionalPremium = false
        promotionalPremiumExpiresAt = nil
        promotionalCreditBalance = 0
        showPostLoginPaywall = true
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
                revenueCatPremium = false
            }
        } catch {
            alertMessage = "Satın alma hesabı güncellenemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin."
        }
    }

    private func refreshPromotionalAccess() async {
#if canImport(FirebaseFunctions)
        guard FirebaseApp.app() != nil else { return }
        do {
            let result = try await functions.httpsCallable("getAccountAccessState").call([:])
            guard let payload = result.data as? [String: Any] else { return }
            promotionalPremium = payload["promotionalPremiumActive"] as? Bool ?? false
            purchasedCreditBalance = max(
                0,
                payload["purchasedCreditBalance"] as? Int ?? 0
            )
            promotionalCreditBalance = max(
                0,
                payload["promotionalCreditBalance"] as? Int ?? 0
            )
            showPostLoginPaywall = payload["showPostLoginPaywall"] as? Bool ?? true
            if let rawDate = payload["promotionalPremiumExpiresAt"] as? String {
                promotionalPremiumExpiresAt = ISO8601DateFormatter().date(from: rawDate)
            } else {
                promotionalPremiumExpiresAt = nil
            }
        } catch {
            // Preserve the last server-confirmed state during a temporary outage.
        }
#endif
    }

    private func consumeServerCredit() async -> Bool {
#if canImport(FirebaseFunctions)
        guard FirebaseApp.app() != nil, creditBalance > 0 else { return false }
        do {
            let result = try await functions.httpsCallable("consumePromotionalCredit").call([:])
            guard let payload = result.data as? [String: Any],
                  let authorized = payload["authorized"] as? Bool else { return false }
            promotionalPremium = payload["promotionalPremiumActive"] as? Bool ?? promotionalPremium
            purchasedCreditBalance = max(
                0,
                payload["purchasedCreditBalance"] as? Int ?? purchasedCreditBalance
            )
            promotionalCreditBalance = max(
                0,
                payload["promotionalCreditBalance"] as? Int ?? promotionalCreditBalance
            )
            return authorized
        } catch {
            return false
        }
#else
        return false
#endif
    }

    private func syncPurchaseSnapshot() async {
#if canImport(FirebaseFunctions)
        guard FirebaseApp.app() != nil, activeAccountID != nil else { return }
        do {
            _ = try await functions.httpsCallable("syncPurchaseSnapshot").call([
                "revenueCatPremiumActive": revenueCatPremium
            ])
        } catch {
            // This snapshot is observability for the admin panel only. A temporary
            // sync failure must never block purchases, lookups, or account access.
        }
#endif
    }

    private struct CreditClaimResult {
        let creditedAmount: Int
    }

    private var pendingCreditClaimsStorageKey: String {
        guard let activeAccountID else { return Self.pendingSignedCreditTransactionsKey }
        return "\(Self.pendingSignedCreditTransactionsKey).account.\(activeAccountID)"
    }

    private func signedTransactionJWS(
        for productID: RevenueCatProductID,
        storeTransaction: StoreTransaction
    ) async -> String? {
        guard let purchasedTransaction = storeTransaction.sk2Transaction,
              purchasedTransaction.productID == productID.rawValue,
              let verificationResult = await StoreKit.Transaction.latest(for: productID.rawValue)
        else { return nil }

        switch verificationResult {
        case let .verified(latestTransaction) where latestTransaction.id == purchasedTransaction.id:
            return verificationResult.jwsRepresentation
        default:
            return nil
        }
    }

    private func enqueuePendingCreditClaim(_ signedTransaction: String) {
        var claims = Set(defaults.stringArray(forKey: pendingCreditClaimsStorageKey) ?? [])
        claims.insert(signedTransaction)
        defaults.set(Array(claims), forKey: pendingCreditClaimsStorageKey)
    }

    private func removePendingCreditClaim(_ signedTransaction: String) {
        var claims = Set(defaults.stringArray(forKey: pendingCreditClaimsStorageKey) ?? [])
        claims.remove(signedTransaction)
        defaults.set(Array(claims), forKey: pendingCreditClaimsStorageKey)
    }

    private func retryPendingCreditClaims() async {
        guard activeAccountID != nil else { return }
        let pendingClaims = defaults.stringArray(forKey: pendingCreditClaimsStorageKey) ?? []
        for signedTransaction in pendingClaims {
            if await claimPurchasedCredits(signedTransaction) != nil {
                removePendingCreditClaim(signedTransaction)
            }
        }
    }

    private func claimPurchasedCredits(_ signedTransaction: String) async -> CreditClaimResult? {
#if canImport(FirebaseFunctions)
        guard FirebaseApp.app() != nil, activeAccountID != nil else { return nil }
        do {
            let result = try await functions.httpsCallable("claimPurchasedCredits").call([
                "signedTransaction": signedTransaction
            ])
            guard let payload = result.data as? [String: Any],
                  let purchasedBalance = payload["purchasedCreditBalance"] as? Int
            else { return nil }
            purchasedCreditBalance = max(0, purchasedBalance)
            return CreditClaimResult(creditedAmount: max(0, payload["creditedAmount"] as? Int ?? 0))
        } catch {
            return nil
        }
#else
        return nil
#endif
    }

#if DEBUG
    func setServerCreditBalancesForTesting(purchased: Int, promotional: Int) {
        purchasedCreditBalance = max(0, purchased)
        promotionalCreditBalance = max(0, promotional)
    }

    func applyCreditHistoryForTesting(_ records: [CreditPurchaseRecord]) {
        creditPurchaseHistory = records.sorted { $0.purchaseDate > $1.purchaseDate }
    }
#endif
}
