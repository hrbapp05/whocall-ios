import XCTest
@testable import Whocall

final class AuthServiceTests: XCTestCase {
    func testDevelopmentAuthAcceptsCanonicalTurkishMobileNumber() async throws {
        let verificationID = try await DevelopmentAuthService().sendVerificationCode(to: "+905065055555")
        XCTAssertEqual(verificationID, "development-verification")
    }

    func testDevelopmentAuthRejectsMalformedCode() async {
        do {
            try await DevelopmentAuthService().verify(verificationID: "development-verification", code: "12")
            XCTFail("Expected invalid code")
        } catch {
            XCTAssertEqual(error as? AuthError, .invalidCode)
        }
    }
}
