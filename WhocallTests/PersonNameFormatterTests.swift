import XCTest
@testable import Whocall

final class PersonNameFormatterTests: XCTestCase {
    func testMasksUppercaseTurkishName() {
        XCTAssertEqual(
            PersonNameFormatter.privacySafeDisplayName(
                firstName: "ESME",
                lastName: "SOLMAZ",
                fallback: "ESME SOLMAZ"
            ),
            "Esme S."
        )
    }

    func testMasksFallbackFullName() {
        XCTAssertEqual(PersonNameFormatter.maskFullName("İPEK IŞIK"), "İpek I.")
    }

    func testAlreadyMaskedNameStaysMasked() {
        XCTAssertEqual(PersonNameFormatter.maskFullName("Ahmet S."), "Ahmet S.")
    }

    func testPrivacySafeOwnerDoesNotRetainSurname() {
        let owner = PhoneOwner(
            phoneNumber: "+905061585598",
            displayName: "ESME SOLMAZ",
            firstName: "ESME",
            lastName: "SOLMAZ"
        ).privacySafe

        XCTAssertEqual(owner.displayName, "Esme S.")
        XCTAssertEqual(owner.firstName, "Esme")
        XCTAssertEqual(owner.lastName, "S.")
        XCTAssertFalse(owner.displayName.contains("Solmaz"))
    }
}
