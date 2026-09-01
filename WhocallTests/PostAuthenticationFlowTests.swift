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

    @Test func remotelyDisabledPaywallLetsCompletedFreeAccountEnterDirectly() {
        let presentation = PostAuthenticationPresentation.make(
            requiresProfileCompletion: false,
            isPremium: false,
            showPostLoginPaywall: false
        )

        #expect(presentation == nil)
    }

    @Test func remotelyDisabledPaywallStillCompletesMissingProfile() throws {
        let presentation = try #require(PostAuthenticationPresentation.make(
            requiresProfileCompletion: true,
            isPremium: false,
            showPostLoginPaywall: false
        ))

        #expect(!presentation.showsPaywall)
        #expect(presentation.requiresProfileCompletion)
    }
}
