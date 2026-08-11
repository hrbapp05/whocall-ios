import Foundation

struct APIConfig: Sendable {
    let baseURL: URL
    let apiKey: String

    static let live = APIConfig(
        baseURL: URL(string: "https://whocallapp.online")!,
        apiKey: Bundle.main.object(forInfoDictionaryKey: "WHOCALL_API_KEY") as? String ?? ""
    )
}

