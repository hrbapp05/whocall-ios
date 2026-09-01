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

    func testTooManyRequestsStartsProtectiveCooldown() {
        XCTAssertEqual(
            PhoneVerificationRetryPolicy.cooldown(for: .tooManyRequests),
            15 * 60
        )
        XCTAssertNil(PhoneVerificationRetryPolicy.cooldown(for: .networkUnavailable))
    }

    func testTooManyRequestsMessageDoesNotExposeInfrastructureDetails() {
        let message = AuthError.tooManyRequests.localizedDescription

        XCTAssertEqual(
            message,
            "Şu anda doğrulama kodu gönderemiyoruz. Lütfen daha sonra tekrar deneyin."
        )
        XCTAssertFalse(message.localizedCaseInsensitiveContains("Blaze"))
        XCTAssertFalse(message.localizedCaseInsensitiveContains("Firebase"))
    }

#if canImport(FirebaseAuth)
    func testFirebaseAppVerificationErrorsUseActionableMessage() {
        let firebaseError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.appNotVerified.rawValue
        )

        XCTAssertEqual(FirebasePhoneAuthService.localized(firebaseError), .appVerificationFailed)
    }

    func testFirebaseBillingErrorUsesActionableMessage() {
        let firebaseError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.internalError.rawValue,
            userInfo: [AuthErrorUserInfoNameKey: "ERROR_BILLING_NOT_ENABLED"]
        )

        XCTAssertEqual(FirebasePhoneAuthService.localized(firebaseError), .billingRequired)
    }

    func testFirebaseTooManyRequestsIsNotReportedAsProjectQuota() {
        let firebaseError = NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.tooManyRequests.rawValue
        )

        XCTAssertEqual(FirebasePhoneAuthService.localized(firebaseError), .tooManyRequests)
    }

    func testUnknownFirebaseErrorExposesNonPIITechnicalCode() {
        let firebaseError = NSError(domain: "FIRAuthErrorDomain", code: 17_777)

        XCTAssertEqual(FirebasePhoneAuthService.localized(firebaseError), .serviceFailure(code: 17_777))
    }
#endif
}
