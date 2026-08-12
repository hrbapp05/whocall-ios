import Testing
@testable import Whocall

struct CommunitySafetyTests {
    @Test func trustLevelUsesReportThresholds() {
        #expect(CommunityTrustLevel(reportCount: 0) == .high)
        #expect(CommunityTrustLevel(reportCount: 2) == .high)
        #expect(CommunityTrustLevel(reportCount: 3) == .medium)
        #expect(CommunityTrustLevel(reportCount: 19) == .medium)
        #expect(CommunityTrustLevel(reportCount: 20) == .medium)
        #expect(CommunityTrustLevel(reportCount: 21) == .risky)
    }

    @Test func moderationBlocksInsultsAndAllowsOrdinaryLabels() {
        #expect(CommunityContentModerator.containsBlockedLanguage("ŞEREFSİZ arayan"))
        #expect(CommunityContentModerator.containsBlockedLanguage("s i k t i r"))
        #expect(!CommunityContentModerator.containsBlockedLanguage("Güvenilir tesisatçı"))
    }
}
