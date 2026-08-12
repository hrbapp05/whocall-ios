import XCTest
@testable import Whocall

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

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

    func testPhoneFormatterDisplaysEveryDigitWithoutClippingData() {
        XCTAssertEqual(TurkishPhoneNumberFormatter.display("5065055555"), "(506) 505 55 55")
        XCTAssertEqual(TurkishPhoneNumberFormatter.display("5065"), "(506) 5")
    }

#if canImport(FirebaseAuth)
    func testFirebaseAppVerificationErrorsUseActionableMessage() {
        let firebaseError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.appNotVerified.rawValue
        )

        XCTAssertEqual(FirebasePhoneAuthService.localized(firebaseError), .appVerificationFailed)
    }
#endif
}
