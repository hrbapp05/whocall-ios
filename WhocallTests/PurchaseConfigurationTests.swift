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
    func testLegacyPlaceholderCreditsAreRemoved() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(5, forKey: PurchaseStore.creditBalanceKey)

        let store = PurchaseStore(defaults: defaults)

        XCTAssertEqual(store.creditBalance, 0)
        XCTAssertFalse(store.hasLookupAccess)
    }

    @MainActor
    func testPurchasedCreditAuthorizesExactlyOneLookup() async throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: PurchaseStore.creditBalanceMigrationKey)
        defaults.set(1, forKey: PurchaseStore.creditBalanceKey)
        let store = PurchaseStore(defaults: defaults)

        let firstAuthorization = await store.authorizeLookupResult()
        XCTAssertTrue(firstAuthorization)
        XCTAssertEqual(store.creditBalance, 0)
        let secondAuthorization = await store.authorizeLookupResult()
        XCTAssertFalse(secondAuthorization)
    }

    @MainActor
    func testFreeUserCannotRevealLookupResult() async throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: PurchaseStore.creditBalanceMigrationKey)
        defaults.set(0, forKey: PurchaseStore.creditBalanceKey)

        let store = PurchaseStore(defaults: defaults)

        XCTAssertFalse(store.hasLookupAccess)
        let authorization = await store.authorizeLookupResult()
        XCTAssertFalse(authorization)
        XCTAssertEqual(store.creditBalance, 0)
    }

    @MainActor
    func testMigrationPreservesPreviouslyPurchasedCredits() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(8, forKey: PurchaseStore.creditBalanceKey)

        let store = PurchaseStore(defaults: defaults)

        XCTAssertEqual(store.creditBalance, 8)
    }

    @MainActor
    func testCreditsAreIsolatedBetweenVerifiedAccounts() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(2, forKey: "\(PurchaseStore.creditBalanceKey).account.account-a")
        defaults.set(7, forKey: "\(PurchaseStore.creditBalanceKey).account.account-b")

        let store = PurchaseStore(defaults: defaults)
        store.switchAccountForTesting("account-a")
        XCTAssertEqual(store.creditBalance, 2)

        store.switchAccountForTesting("account-b")
        XCTAssertEqual(store.creditBalance, 7)
    }

    @MainActor
    func testRevenueCatHistoryReconcilesCreditsExactlyOnce() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: PurchaseStore.creditBalanceMigrationKey)
        let store = PurchaseStore(defaults: defaults)
        store.switchAccountForTesting("account-a")
        let purchase = CreditPurchaseRecord(
            id: "transaction-1",
            productID: RevenueCatProductID.credits5.rawValue,
            title: RevenueCatProductID.credits5.displayName,
            creditAmount: 5,
            purchaseDate: Date()
        )

        store.reconcileCreditHistoryForTesting([purchase])
        store.reconcileCreditHistoryForTesting([purchase])

        XCTAssertEqual(store.creditBalance, 5)
    }
}
