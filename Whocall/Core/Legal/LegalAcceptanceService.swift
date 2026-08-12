import Foundation

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
#endif

#if canImport(FirebaseFunctions)
@preconcurrency import FirebaseFunctions
#endif

enum LegalPolicy {
    static let termsVersion = "2026-08-12.1"
    static let privacyNoticeVersion = "2026-08-12.1"

    static let privacyPolicyURL = URL(
        string: "https://whocall-turkiye.mitisen.chatgpt.site/privacy-policy"
    )!
    static let termsOfUseURL = URL(
        string: "https://whocall-turkiye.mitisen.chatgpt.site/terms-of-use"
    )!
}

enum LegalAcceptanceError: LocalizedError {
    case configurationMissing
    case authenticationRequired
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            "Yasal tercih servisi bu build için yapılandırılmamış."
        case .authenticationRequired:
            "Kabul kaydı için telefon doğrulamasını tamamlayın."
        case .serviceUnavailable:
            "Tercihiniz kaydedilemedi. Bağlantınızı kontrol edip tekrar deneyin."
        }
    }
}

protocol LegalAccountServicing {
    @MainActor func recordCurrentAcceptance() async throws
    @MainActor func deleteCurrentAccount() async throws
}

enum LegalAccountServiceFactory {
    @MainActor
    static func live() -> any LegalAccountServicing {
#if canImport(FirebaseAuth) && canImport(FirebaseFunctions)
        if FirebaseApp.app() != nil {
            return FirebaseLegalAccountService()
        }
#endif
        return DevelopmentLegalAccountService()
    }
}

@MainActor
struct DevelopmentLegalAccountService: LegalAccountServicing {
    func recordCurrentAcceptance() async throws {
        LegalAcceptancePreference.clearPending()
    }

    func deleteCurrentAccount() async throws {}
}

#if canImport(FirebaseAuth) && canImport(FirebaseFunctions)
@MainActor
struct FirebaseLegalAccountService: LegalAccountServicing {
    private let functions = Functions.functions(region: "europe-west1")

    func recordCurrentAcceptance() async throws {
        guard FirebaseApp.app() != nil,
              let user = Auth.auth().currentUser,
              user.phoneNumber?.isEmpty == false else {
            throw LegalAcceptanceError.authenticationRequired
        }

        do {
            _ = try await functions.httpsCallable("recordLegalAcceptance").call([
                "termsVersion": LegalPolicy.termsVersion,
                "privacyNoticeVersion": LegalPolicy.privacyNoticeVersion,
                "termsAccepted": true,
                "privacyNoticeAcknowledged": true,
                "appVersion": appVersion,
                "locale": "tr-TR",
            ])
            LegalAcceptancePreference.setAcceptedCurrent(userID: user.uid)
            LegalAcceptancePreference.clearPending()
        } catch let error as LegalAcceptanceError {
            throw error
        } catch {
            throw LegalAcceptanceError.serviceUnavailable
        }
    }

    func deleteCurrentAccount() async throws {
        guard FirebaseApp.app() != nil,
              Auth.auth().currentUser?.phoneNumber?.isEmpty == false else {
            throw LegalAcceptanceError.authenticationRequired
        }

        do {
            _ = try await functions.httpsCallable("deleteWhoCallAccount").call()
        } catch {
            throw LegalAcceptanceError.serviceUnavailable
        }
    }

    private var appVersion: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        switch (shortVersion, build) {
        case let (.some(version), .some(build)):
            return "\(version) (\(build))"
        case let (.some(version), .none):
            return version
        case let (.none, .some(build)):
            return build
        case (.none, .none):
            return "unknown"
        }
    }
}
#endif

enum LegalAcceptancePreference {
    private static let pendingKey = "whocall.legalAcceptance.pending.v1"
    private static let acceptedKeyPrefix = "whocall.legalAcceptance.accepted"

    static func markPending(defaults: UserDefaults = .standard) {
        defaults.set(currentSignature, forKey: pendingKey)
    }

    static func hasPending(defaults: UserDefaults = .standard) -> Bool {
        defaults.string(forKey: pendingKey) == currentSignature
    }

    static func clearPending(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: pendingKey)
    }

    static func hasAcceptedCurrent(userID: String, defaults: UserDefaults = .standard) -> Bool {
        defaults.string(forKey: acceptedKey(userID: userID)) == currentSignature
    }

    static func setAcceptedCurrent(userID: String, defaults: UserDefaults = .standard) {
        defaults.set(currentSignature, forKey: acceptedKey(userID: userID))
    }

    static func clear(userID: String, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: acceptedKey(userID: userID))
        clearPending(defaults: defaults)
    }

    private static var currentSignature: String {
        "terms:\(LegalPolicy.termsVersion)|notice:\(LegalPolicy.privacyNoticeVersion)"
    }

    private static func acceptedKey(userID: String) -> String {
        "\(acceptedKeyPrefix).\(userID)"
    }
}
