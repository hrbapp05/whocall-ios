import XCTest
@testable import Whocall

final class AuthServiceTests: XCTestCase {
    func testDevelopmentAuthAcceptsCanonicalTurkishMobileNumber() async throws {
        try await DevelopmentAuthService().sendVerificationCode(to: "5065055555")
    }

    func testDevelopmentAuthRejectsMalformedCode() async {
        do {
            try await DevelopmentAuthService().verify(code: "12")
            XCTFail("Expected invalid code")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidCode)
        }
    }
}
