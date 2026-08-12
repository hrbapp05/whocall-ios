import Testing
@testable import Whocall

struct PostAuthenticationFlowTests {
    @Test func freeAccountSeesPaywall() throws {
        let presentation = try #require(
            PostAuthenticationPresentation.make(
                requiresProfileCompletion: false,
                isPremium: false
            )
        )

        #expect(presentation.showsPaywall)
        #expect(!presentation.requiresProfileCompletion)
    }

    @Test func premiumAccountWithCompleteProfileEntersAppDirectly() {
        let presentation = PostAuthenticationPresentation.make(
            requiresProfileCompletion: false,
            isPremium: true
        )

        #expect(presentation == nil)
    }

    @Test func premiumAccountOnlyCompletesMissingProfile() throws {
        let presentation = try #require(
            PostAuthenticationPresentation.make(
                requiresProfileCompletion: true,
                isPremium: true
            )
        )

        #expect(!presentation.showsPaywall)
        #expect(presentation.requiresProfileCompletion)
    }
}
