import XCTest
@testable import Whocall

final class MetaAttributionConfigurationTests: XCTestCase {
    func testClientConfigurationRejectsMissingAndPlaceholderValues() {
        XCTAssertFalse(MetaAttributionConfiguration.isUsableClientValue(nil))
        XCTAssertFalse(MetaAttributionConfiguration.isUsableClientValue(""))
        XCTAssertFalse(MetaAttributionConfiguration.isUsableClientValue("$(META_APP_ID)"))
        XCTAssertFalse(MetaAttributionConfiguration.isUsableClientValue("replace-me"))
    }

    func testClientConfigurationAcceptsPublicMetaValues() {
        XCTAssertTrue(MetaAttributionConfiguration.isUsableClientValue("123456789012345"))
        XCTAssertTrue(MetaAttributionConfiguration.isUsableClientValue("public-client-token"))
    }
}
