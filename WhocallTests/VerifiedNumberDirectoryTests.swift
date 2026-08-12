import XCTest
@testable import Whocall

@MainActor
final class VerifiedNumberDirectoryTests: XCTestCase {
    func testVerifiedProfileWinsBeforeLegacyAPI() async throws {
        let verified = PhoneOwner(
            phoneNumber: "905061585598",
            displayName: "Doğrulanmış Kullanıcı",
            firstName: "Doğrulanmış",
            lastName: "Kullanıcı"
        )
        let api = WhoCallAPIClient(
            config: APIConfig(baseURL: URL(string: "http://127.0.0.1:1")!, apiKey: "")
        )
        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(owner: verified),
            apiClient: api
        )

        let result = try await service.lookup(number: "5061585598")

        XCTAssertEqual(result, verified.privacySafe)
        XCTAssertEqual(result.displayName, "Doğrulanmış K.")
    }
}

@MainActor
private struct StubVerifiedDirectory: VerifiedNumberDirectoryServicing {
    let owner: PhoneOwner?

    func publishOwnProfile(firstName: String, lastName: String) async throws {}
    func lookup(number: String) async throws -> PhoneOwner? { owner }
}
