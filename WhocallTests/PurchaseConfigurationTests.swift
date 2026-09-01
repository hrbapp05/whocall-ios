import XCTest
@testable import Whocall

final class PurchaseConfigurationTests: XCTestCase {
    func testProductIdentifiersMatchAppStoreCatalog() {
        XCTAssertEqual(
            Set(RevenueCatProductID.allCases.map(\.rawValue)),
            [
                "com.levelappstudio.whocall.premium.weekly",
                "com.levelappstudio.whocall.premium.monthly",
                "com.levelappstudio.whocall.credits.3",
                "com.levelappstudio.whocall.credits.5",
                "com.levelappstudio.whocall.credits.10"
            ]
        )
    }

    func testOnlyCreditProductsExposeCreditAmounts() {
        XCTAssertNil(RevenueCatProductID.premiumWeekly.creditAmount)
        XCTAssertNil(RevenueCatProductID.premiumMonthly.creditAmount)
        XCTAssertEqual(RevenueCatProductID.credits3.creditAmount, 3)
        XCTAssertEqual(RevenueCatProductID.credits5.creditAmount, 5)
        XCTAssertEqual(RevenueCatProductID.credits10.creditAmount, 10)
    }

    func testOnlySubscriptionProductsUnlockPremium() {
        XCTAssertTrue(RevenueCatProductID.unlocksPremium(
            productIdentifier: RevenueCatProductID.premiumWeekly.rawValue
        ))
        XCTAssertTrue(RevenueCatProductID.unlocksPremium(
            productIdentifier: RevenueCatProductID.premiumMonthly.rawValue
        ))
        XCTAssertFalse(RevenueCatProductID.unlocksPremium(
            productIdentifier: RevenueCatProductID.credits5.rawValue
        ))
    }

    func testCreditBadgeShowsPurchasedBalanceBeforePremiumInfinity() {
        let premiumWithCredits = CreditBadgePresentation(isPremium: true, creditBalance: 5)
        XCTAssertEqual(premiumWithCredits.text, "5")
        XCTAssertEqual(
            premiumWithCredits.accessibilityLabel,
            "5 kredi; Premium ile sınırsız sorgulama"
        )
        XCTAssertEqual(
            CreditBadgePresentation(isPremium: true, creditBalance: 0).text,
            "∞"
        )
    }

    func testRevenueCatKeyValidationRejectsPlaceholders() {
        XCTAssertFalse(RevenueCatConfiguration.isUsablePublicSDKKey(""))
        XCTAssertFalse(RevenueCatConfiguration.isUsablePublicSDKKey("$(REVENUECAT_PUBLIC_SDK_KEY)"))
        XCTAssertFalse(RevenueCatConfiguration.isUsablePublicSDKKey("replace-me"))
        XCTAssertTrue(RevenueCatConfiguration.isUsablePublicSDKKey("public-example-key"))
    }

    @MainActor
    func testLocalDefaultsNeverSeedAccountCreditBalance() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(35, forKey: PurchaseStore.creditBalanceKey)

        let store = PurchaseStore(defaults: defaults)

        XCTAssertEqual(store.creditBalance, 0)
        XCTAssertFalse(store.hasLookupAccess)
    }

    @MainActor
    func testCreditBalanceCombinesServerManagedBalances() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PurchaseStore(defaults: defaults)

        store.setServerCreditBalancesForTesting(purchased: 8, promotional: 2)

        XCTAssertEqual(store.creditBalance, 10)
        XCTAssertTrue(store.hasLookupAccess)
    }

    @MainActor
    func testSwitchingVerifiedAccountClearsPreviousServerBalance() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PurchaseStore(defaults: defaults)
        store.switchAccountForTesting("account-a")
        store.setServerCreditBalancesForTesting(purchased: 7, promotional: 1)
        XCTAssertEqual(store.creditBalance, 8)

        store.switchAccountForTesting("account-b")

        XCTAssertFalse(store.hasLookupAccess)
        XCTAssertEqual(store.creditBalance, 0)
    }

    @MainActor
    func testRevenueCatHistoryNeverMintsCreditsAfterReinstall() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = PurchaseStore(defaults: defaults)
        store.switchAccountForTesting("account-a")
        store.setServerCreditBalancesForTesting(purchased: 2, promotional: 0)
        let historicalPurchase = CreditPurchaseRecord(
            id: "historical-transaction",
            productID: RevenueCatProductID.credits10.rawValue,
            title: RevenueCatProductID.credits10.displayName,
            creditAmount: 10,
            purchaseDate: Date()
        )

        store.applyCreditHistoryForTesting([historicalPurchase])

        XCTAssertEqual(store.creditPurchaseHistory, [historicalPurchase])
        XCTAssertEqual(store.creditBalance, 2)
    }
}
