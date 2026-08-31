import Foundation

enum ReviewPromptStore {
    static let firstSuccessfulPromoLookupKey = "review.firstSuccessfulPromoLookup.v1"

    static func canRequestAfterFirstPromoLookup(defaults: UserDefaults = .standard) -> Bool {
        !defaults.bool(forKey: firstSuccessfulPromoLookupKey)
    }

    static func markFirstPromoLookupRequest(defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: firstSuccessfulPromoLookupKey)
    }
}
