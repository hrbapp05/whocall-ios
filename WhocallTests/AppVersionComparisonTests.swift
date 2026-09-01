import XCTest
@testable import Whocall

final class AppVersionComparisonTests: XCTestCase {
    func testDetectsNewerStoreVersion() {
        XCTAssertTrue(AppVersionComparison.isNewer("1.0.2", than: "1.0.1"))
        XCTAssertTrue(AppVersionComparison.isNewer("2.0", than: "1.9.9"))
    }

    func testDoesNotRequireUpdateForSameOrOlderVersion() {
        XCTAssertFalse(AppVersionComparison.isNewer("1.0.2", than: "1.0.2"))
        XCTAssertFalse(AppVersionComparison.isNewer("1.0.1", than: "1.0.2"))
        XCTAssertFalse(AppVersionComparison.isNewer("1.0", than: "1.0.0"))
    }

    func testComparesVersionsWithDifferentComponentCounts() {
        XCTAssertTrue(AppVersionComparison.isNewer("1.0.1", than: "1"))
        XCTAssertFalse(AppVersionComparison.isNewer("1", than: "1.0.1"))
    }
}
