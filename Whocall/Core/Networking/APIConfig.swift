import Foundation

struct APIConfig: Sendable {
    let baseURL: URL
    let apiKey: String

    static let live: APIConfig = {
        let configuredURL = Bundle.main.object(forInfoDictionaryKey: "WHOCALL_API_BASE_URL") as? String
        let baseURL = configuredURL.flatMap(URL.init(string:))
            ?? URL(string: "https://whocallapp.online")!
        return APIConfig(
            baseURL: baseURL,
            apiKey: Bundle.main.object(forInfoDictionaryKey: "WHOCALL_API_KEY") as? String ?? ""
        )
    }()
}
