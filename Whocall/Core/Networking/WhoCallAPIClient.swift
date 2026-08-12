import Foundation

enum WhoCallClientError: Error, Equatable {
    case invalidRequest
    case invalidResponse
    case server(statusCode: Int, APIErrorResponse?)
}

struct WhoCallAPIClient: Sendable {
    let config: APIConfig
    let session: URLSession

    init(config: APIConfig = .live, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func makeLookupRequest(number: String, requestID: UUID = UUID()) throws -> URLRequest {
        guard var components = URLComponents(
            url: config.baseURL.appending(path: "/api/v1/phone/lookup"),
            resolvingAgainstBaseURL: false
        ) else {
            throw WhoCallClientError.invalidRequest
        }

        components.queryItems = [URLQueryItem(name: "number", value: number)]
        guard let url = components.url else { throw WhoCallClientError.invalidRequest }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(requestID.uuidString.lowercased(), forHTTPHeaderField: "X-Request-Id")
        if !config.apiKey.isEmpty {
            request.setValue(config.apiKey, forHTTPHeaderField: "X-API-Key")
        }
        return request
    }

    func lookup(number: String) async throws -> PhoneOwner {
        let request = try makeLookupRequest(number: number)
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WhoCallClientError.invalidResponse
        }

        let decoder = JSONDecoder()
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw WhoCallClientError.server(
                statusCode: httpResponse.statusCode,
                try? decoder.decode(APIErrorResponse.self, from: data)
            )
        }
        return try decoder.decode(PhoneLookupResponse.self, from: data).data
    }
}

@MainActor
struct PhoneLookupService {
    let directory: any VerifiedNumberDirectoryServicing
    let apiClient: WhoCallAPIClient

    init(
        directory: any VerifiedNumberDirectoryServicing = VerifiedNumberDirectoryFactory.live(),
        apiClient: WhoCallAPIClient = WhoCallAPIClient()
    ) {
        self.directory = directory
        self.apiClient = apiClient
    }

    func lookup(number: String) async throws -> PhoneOwner {
        let profile = ProfileServiceFactory.live()
        if canonical(profile.currentPhoneNumber) == canonical(number),
           !canonical(number).isEmpty,
           !ProfileVisibilityPreference.isVisible(userID: profile.currentUserID) {
            throw VerifiedNumberDirectoryLookupError.hiddenByOwner
        }
        if canonical(profile.currentPhoneNumber) == canonical(number),
           let displayName = profile.currentDisplayName,
           let localOwner = owner(phoneNumber: number, displayName: displayName) {
            return localOwner.privacySafe
        }

        if let directoryResult = try? await directory.lookup(number: number) {
            switch directoryResult {
            case let .found(verifiedOwner):
                return verifiedOwner.privacySafe
            case .hidden:
                throw VerifiedNumberDirectoryLookupError.hiddenByOwner
            case .notRegistered:
                break
            }
        }
        return try await apiClient.lookup(number: number).privacySafe
    }

    private func canonical(_ number: String?) -> String {
        String((number ?? "").filter(\.isNumber).suffix(10))
    }

    private func owner(phoneNumber: String, displayName: String) -> PhoneOwner? {
        let parts = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
        guard let firstName = parts.first, parts.count >= 2 else { return nil }
        return PhoneOwner(
            phoneNumber: canonical(phoneNumber),
            displayName: displayName,
            firstName: String(firstName),
            lastName: String(parts.last ?? firstName)
        )
    }
}

enum VerifiedNumberDirectoryLookupError: Error {
    case hiddenByOwner
}
