import XCTest
@testable import Whocall

@MainActor
final class RecentLookupStoreTests: XCTestCase {
    func testPersistsRealLookupAndReloadsIt() async throws {
        let suiteName = "RecentLookupStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecentLookupStore(defaults: defaults)
        let contacts = ContactService()
        let owner = PhoneOwner(
            phoneNumber: "+905061585598",
            displayName: "Ada Yılmaz",
            firstName: "Ada",
            lastName: "Yılmaz"
        )

        await store.record(owner: owner, contacts: contacts)

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records.first?.displayName, "Ada Yılmaz")
        XCTAssertEqual(store.records.first?.phoneNumber, "+905061585598")

        let reloaded = RecentLookupStore(defaults: defaults)
        XCTAssertEqual(reloaded.records.first?.displayName, "Ada Yılmaz")
    }

    func testDeduplicatesSamePhoneNumber() async throws {
        let suiteName = "RecentLookupStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecentLookupStore(defaults: defaults)
        let contacts = ContactService()

        await store.record(
            owner: PhoneOwner(
                phoneNumber: "+905061585598",
                displayName: "İlk Ad",
                firstName: "İlk",
                lastName: "Ad"
            ),
            contacts: contacts
        )
        await store.record(
            owner: PhoneOwner(
                phoneNumber: "+905061585598",
                displayName: "Güncel Ad",
                firstName: "Güncel",
                lastName: "Ad"
            ),
            contacts: contacts
        )

        XCTAssertEqual(store.records.count, 1)
        XCTAssertEqual(store.records.first?.displayName, "Güncel Ad")
    }
}
