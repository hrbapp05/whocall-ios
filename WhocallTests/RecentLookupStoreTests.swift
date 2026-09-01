import XCTest
@testable import Whocall

@MainActor
final class RecentLookupStoreTests: XCTestCase {
    func testPersistsRealLookupAndReloadsIt() async throws {
        let suiteName = "RecentLookupStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecentLookupStore(defaults: defaults)
        store.activateAccount("account-a")
        let owner = PhoneOwner(
            phoneNumber: "+905000000000",
            displayName: "Ada Yılmaz",
            firstName: "Ada",
            lastName: "Yılmaz"
        )

        store.record(owner: owner)

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records.first?.displayName, "Ada Y.")
        XCTAssertEqual(store.records.first?.phoneNumber, "+905000000000")

        let reloaded = RecentLookupStore(defaults: defaults)
        reloaded.activateAccount("account-a")
        XCTAssertEqual(reloaded.records.first?.displayName, "Ada Y.")
    }

    func testDeduplicatesSamePhoneNumber() async throws {
        let suiteName = "RecentLookupStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecentLookupStore(defaults: defaults)
        store.activateAccount("account-a")

        store.record(
            owner: PhoneOwner(
                phoneNumber: "+905000000000",
                displayName: "İlk Ad",
                firstName: "İlk",
                lastName: "Ad"
            )
        )
        store.record(
            owner: PhoneOwner(
                phoneNumber: "+905000000000",
                displayName: "Güncel Ad",
                firstName: "Güncel",
                lastName: "Ad"
            )
        )

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records.first?.displayName, "Güncel A.")
    }

    func testHistoryIsIsolatedBetweenAccountsOnSameDevice() async throws {
        let suiteName = "RecentLookupStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecentLookupStore(defaults: defaults)
        store.activateAccount("account-a")
        store.record(
            owner: PhoneOwner(
                phoneNumber: "905000000000",
                displayName: "Göktuğ Solmaz",
                firstName: "Göktuğ",
                lastName: "Solmaz"
            )
        )

        store.activateAccount("account-b")
        XCTAssertTrue(store.records.isEmpty)

        store.activateAccount("account-a")
        XCTAssertEqual(store.records.first?.displayName, "Göktuğ S.")
    }
}
