import XCTest
@testable import Whocall

@MainActor
final class VerifiedNumberDirectoryTests: XCTestCase {
    func testVerifiedProfileWinsBeforeLegacyAPI() async throws {
        let verified = PhoneOwner(
            phoneNumber: "905000000000",
            displayName: "Doğrulanmış Kullanıcı",
            firstName: "Doğrulanmış",
            lastName: "Kullanıcı"
        )
        let api = WhoCallAPIClient(
            config: APIConfig(baseURL: URL(string: "http://127.0.0.1:1")!, apiKey: "")
        )
        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(result: .found(verified)),
            apiClient: api
        )

        let result = try await service.lookup(number: "5000000000")

        XCTAssertEqual(result, .found(verified.privacySafe))
    }

    func testLegacyAPIRunsWhenNumberHasNoVerifiedProfile() async throws {
        let apiOwner = PhoneOwner(
            phoneNumber: "905391112233",
            displayName: "Veritabanı Sonucu",
            firstName: "Veritabanı",
            lastName: "Sonucu"
        )
        StubURLProtocol.responseData = Data(
            #"{"success":true,"data":{"phoneNumber":"905391112233","displayName":"Veritabanı Sonucu","firstName":"Veritabanı","lastName":"Sonucu"}}"#.utf8
        )
        StubURLProtocol.statusCode = 200

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(result: .notRegistered),
            apiClient: WhoCallAPIClient(
                config: APIConfig(baseURL: URL(string: "https://whocallapp.online")!, apiKey: "test-key"),
                session: URLSession(configuration: configuration)
            )
        )

        let result = try await service.lookup(number: "5391112233")

        XCTAssertEqual(result, .found(apiOwner.privacySafe))
    }

    func testHiddenProfileDoesNotFallThroughToLegacyAPI() async throws {
        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(result: .hidden),
            apiClient: WhoCallAPIClient(
                config: APIConfig(baseURL: URL(string: "http://127.0.0.1:1")!, apiKey: "")
            )
        )

        let result = try await service.lookup(number: "5061585598")

        XCTAssertEqual(result, .hidden)
    }

    func testMissingLegacyRecordReturnsNotFoundOutcome() async throws {
        StubURLProtocol.responseData = Data(
            #"{"success":false,"error":{"code":"PHONE_NOT_FOUND","message":"Phone number was not found."},"requestId":"018f47a2-7b22-4a29-8a3f-f6419dbbc101"}"#.utf8
        )
        StubURLProtocol.statusCode = 404
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(result: .notRegistered),
            apiClient: WhoCallAPIClient(
                config: APIConfig(baseURL: URL(string: "https://whocallapp.online")!, apiKey: "test-key"),
                session: URLSession(configuration: configuration)
            )
        )

        let result = try await service.lookup(number: "5555555555")

        XCTAssertEqual(result, .notFound)
    }

    func testHiddenRequesterCannotSearchAnotherNumber() async throws {
        let userID = "development-user"
        ProfileVisibilityPreference.setVisible(false, userID: userID)
        defer { ProfileVisibilityPreference.clear(userID: userID) }

        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(result: .notRegistered),
            apiClient: WhoCallAPIClient(
                config: APIConfig(baseURL: URL(string: "http://127.0.0.1:1")!, apiKey: "")
            )
        )

        let result = try await service.lookup(number: "5061585598")

        XCTAssertEqual(result, .requesterHidden)
    }
}

@MainActor
private struct StubVerifiedDirectory: VerifiedNumberDirectoryServicing {
    let result: VerifiedNumberDirectoryLookup

    func publishOwnProfile(firstName: String, lastName: String) async throws {}
    func ownProfileVisibility() async throws -> VerifiedProfileVisibilityState {
        .visible
    }
    func setOwnProfileVisibility(
        _ isVisible: Bool,
        confirmsCooldown: Bool
    ) async throws -> VerifiedProfileVisibilityState {
        VerifiedProfileVisibilityState(
            isVisible: isVisible,
            hideCount: isVisible ? 0 : 1,
            canEnableAt: nil
        )
    }
    func lookup(number: String) async throws -> VerifiedNumberDirectoryLookup {
        result
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData = Data()
    nonisolated(unsafe) static var statusCode = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: Self.statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
              ) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseData)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
