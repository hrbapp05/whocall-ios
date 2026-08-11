import XCTest
@testable import Whocall

final class APIContractTests: XCTestCase {
    func testLookupSuccessDecodingMatchesLiveOpenAPI() throws {
        let data = Data(#"{"success":true,"data":{"phoneNumber":"+905321234567","displayName":"Example Name","firstName":"Example","lastName":"Name"}}"#.utf8)

        let response = try JSONDecoder().decode(PhoneLookupResponse.self, from: data)

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.data.phoneNumber, "+905321234567")
        XCTAssertEqual(response.data.displayName, "Example Name")
    }

    func testErrorDecodingMatchesCanonicalEnvelope() throws {
        let data = Data(#"{"success":false,"error":{"code":"PHONE_NOT_FOUND","message":"Phone number was not found."},"requestId":"018f47a2-7b22-4a29-8a3f-f6419dbbc101"}"#.utf8)

        let response = try JSONDecoder().decode(APIErrorResponse.self, from: data)

        XCTAssertFalse(response.success)
        XCTAssertEqual(response.error.code, .phoneNotFound)
    }

    func testLookupRequestUsesContractHeadersAndQuery() throws {
        let config = APIConfig(baseURL: URL(string: "https://whocallapp.online")!, apiKey: "test-key")
        let client = WhoCallAPIClient(config: config)
        let id = UUID(uuidString: "018f47a2-7b22-4a29-8a3f-f6419dbbc101")!

        let request = try client.makeLookupRequest(number: "+90 532 123 45 67", requestID: id)
        let components = URLComponents(url: try XCTUnwrap(request.url), resolvingAgainstBaseURL: false)

        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-API-Key"), "test-key")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Request-Id"), id.uuidString.lowercased())
        XCTAssertEqual(components?.queryItems?.first?.value, "+90 532 123 45 67")
    }
}

