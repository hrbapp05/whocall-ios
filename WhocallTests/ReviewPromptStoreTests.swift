import XCTest
@testable import Whocall

final class ReviewPromptStoreTests: XCTestCase {
    func testFirstSuccessfulPromoLookupCanRequestOnlyOnce() throws {
        let suiteName = "ReviewPromptStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(ReviewPromptStore.canRequestAfterFirstPromoLookup(defaults: defaults))

        ReviewPromptStore.markFirstPromoLookupRequest(defaults: defaults)

        XCTAssertFalse(ReviewPromptStore.canRequestAfterFirstPromoLookup(defaults: defaults))
    }
}
