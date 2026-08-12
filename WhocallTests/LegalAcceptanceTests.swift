import XCTest
@testable import Whocall

final class LegalAcceptanceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "LegalAcceptanceTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testPendingAcceptanceUsesCurrentDocumentVersions() {
        XCTAssertFalse(LegalAcceptancePreference.hasPending(defaults: defaults))
        LegalAcceptancePreference.markPending(defaults: defaults)
        XCTAssertTrue(LegalAcceptancePreference.hasPending(defaults: defaults))
        LegalAcceptancePreference.clearPending(defaults: defaults)
        XCTAssertFalse(LegalAcceptancePreference.hasPending(defaults: defaults))
    }

    func testAcceptanceIsScopedToFirebaseUser() {
        LegalAcceptancePreference.setAcceptedCurrent(userID: "user-a", defaults: defaults)

        XCTAssertTrue(
            LegalAcceptancePreference.hasAcceptedCurrent(userID: "user-a", defaults: defaults)
        )
        XCTAssertFalse(
            LegalAcceptancePreference.hasAcceptedCurrent(userID: "user-b", defaults: defaults)
        )

        LegalAcceptancePreference.clear(userID: "user-a", defaults: defaults)
        XCTAssertFalse(
            LegalAcceptancePreference.hasAcceptedCurrent(userID: "user-a", defaults: defaults)
        )
    }
}
