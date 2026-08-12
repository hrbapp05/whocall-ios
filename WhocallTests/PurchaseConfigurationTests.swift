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
    func testPurchasedCreditAuthorizesExactlyOneLookup() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: PurchaseStore.creditBalanceMigrationKey)
        defaults.set(1, forKey: PurchaseStore.creditBalanceKey)
        let store = PurchaseStore(defaults: defaults)

        XCTAssertTrue(store.authorizeLookupResult())
        XCTAssertEqual(store.creditBalance, 0)
        XCTAssertFalse(store.authorizeLookupResult())
    }

    @MainActor
    func testFreeUserCannotRevealLookupResult() throws {
        let suiteName = "PurchaseStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: PurchaseStore.creditBalanceMigrationKey)
        defaults.set(0, forKey: PurchaseStore.creditBalanceKey)

        let store = PurchaseStore(defaults: defaults)

        XCTAssertFalse(store.hasLookupAccess)
        XCTAssertFalse(store.authorizeLookupResult())
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
}
