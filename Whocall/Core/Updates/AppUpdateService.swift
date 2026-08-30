import Foundation

struct RequiredAppUpdate: Identifiable, Equatable, Sendable {
    let version: String
    let storeURL: URL

    var id: String { version }
}

struct AppUpdateService: Sendable {
    static let appStoreID = "6800227705"
    static let fallbackStoreURL = URL(string: "https://apps.apple.com/tr/app/id\(appStoreID)")!

    let session: URLSession
    let bundle: Bundle

    init(session: URLSession = .shared, bundle: Bundle = .main) {
        self.session = session
        self.bundle = bundle
    }

    func requiredUpdate() async -> RequiredAppUpdate? {
        guard let currentVersion = bundle.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String,
        let url = URL(string: "https://itunes.apple.com/lookup?id=\(Self.appStoreID)&country=tr") else {
            return nil
        }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 8
            request.cachePolicy = .reloadRevalidatingCacheData
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200..<300).contains(response.statusCode),
                  let result = try JSONDecoder().decode(AppStoreLookupEnvelope.self, from: data)
                    .results.first,
                  AppVersionComparison.isNewer(result.version, than: currentVersion) else {
                return nil
            }
            return RequiredAppUpdate(
                version: result.version,
                storeURL: result.trackViewURL ?? Self.fallbackStoreURL
            )
        } catch {
            // A temporary App Store lookup failure must never block launch.
            return nil
        }
    }
}

enum AppVersionComparison {
    static func isNewer(_ candidate: String, than current: String) -> Bool {
        let candidateParts = numericParts(candidate)
        let currentParts = numericParts(current)
        let count = max(candidateParts.count, currentParts.count)
        for index in 0..<count {
            let candidateValue = index < candidateParts.count ? candidateParts[index] : 0
            let currentValue = index < currentParts.count ? currentParts[index] : 0
            if candidateValue != currentValue { return candidateValue > currentValue }
        }
        return false
    }

    private static func numericParts(_ value: String) -> [Int] {
        value.split(separator: ".").map { part in
            Int(part.prefix(while: \.isNumber)) ?? 0
        }
    }
}

private struct AppStoreLookupEnvelope: Decodable {
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    let version: String
    let trackViewURL: URL?

    enum CodingKeys: String, CodingKey {
        case version
        case trackViewURL = "trackViewUrl"
    }
}
