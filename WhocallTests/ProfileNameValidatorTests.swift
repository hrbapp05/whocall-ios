import Testing
@testable import Whocall

struct ProfileNameValidatorTests {
    @Test func acceptsRealTurkishNames() {
        #expect(ProfileNameValidator.validated("  Göktuğ  ", field: .firstName) == "Göktuğ")
        #expect(ProfileNameValidator.validated("Nur-Su", field: .firstName) == "Nur-Su")
        #expect(ProfileNameValidator.validated("Öztürk", field: .lastName) == "Öztürk")
    }

    @Test func rejectsBlankInitialNumericAndPlaceholderValues() {
        #expect(ProfileNameValidator.validated("   ", field: .firstName) == nil)
        #expect(ProfileNameValidator.validated("S.", field: .lastName) == nil)
        #expect(ProfileNameValidator.validated("Ali123", field: .firstName) == nil)
        #expect(ProfileNameValidator.validated("Test", field: .firstName) == nil)
        #expect(ProfileNameValidator.validated("WhoCall", field: .lastName) == nil)
    }

    @Test func rejectsAbusiveAndMeaninglessValues() {
        #expect(ProfileNameValidator.validated("Şerefsiz", field: .lastName) == nil)
        #expect(ProfileNameValidator.validated("Aaaaa", field: .firstName) == nil)
        #expect(ProfileNameValidator.validated("Qwerty", field: .firstName) == nil)
    }

    @Test func requiresACompleteValidDisplayName() {
        #expect(ProfileNameValidator.isCompleteDisplayName("Göktuğ Solmaz"))
        #expect(ProfileNameValidator.isCompleteDisplayName("Nur Su Öztürk"))
        #expect(!ProfileNameValidator.isCompleteDisplayName(nil))
        #expect(!ProfileNameValidator.isCompleteDisplayName("Göktuğ"))
        #expect(!ProfileNameValidator.isCompleteDisplayName("Test Kullanıcı"))
    }
}
