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
            directory: StubVerifiedDirectory(owner: verified),
            apiClient: api
        )

        let result = try await service.lookup(number: "5000000000")

        XCTAssertEqual(result, verified.privacySafe)
        XCTAssertEqual(result.displayName, "Doğrulanmış K.")
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

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let service = PhoneLookupService(
            directory: StubVerifiedDirectory(owner: nil),
            apiClient: WhoCallAPIClient(
                config: APIConfig(baseURL: URL(string: "https://whocallapp.online")!, apiKey: "test-key"),
                session: URLSession(configuration: configuration)
            )
        )

        let result = try await service.lookup(number: "5391112233")

        XCTAssertEqual(result, apiOwner.privacySafe)
        XCTAssertEqual(result.displayName, "Veritabanı S.")
    }
}

@MainActor
private struct StubVerifiedDirectory: VerifiedNumberDirectoryServicing {
    let owner: PhoneOwner?

    func publishOwnProfile(firstName: String, lastName: String) async throws {}
    func setOwnProfileVisibility(_ isVisible: Bool) async throws {}
    func lookup(number: String) async throws -> VerifiedNumberDirectoryLookup {
        owner.map(VerifiedNumberDirectoryLookup.found) ?? .notRegistered
    }
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var responseData = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(
                url: url,
                statusCode: 200,
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
