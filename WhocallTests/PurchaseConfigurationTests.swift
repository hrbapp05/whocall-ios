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
}
