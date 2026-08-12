import Foundation

#if canImport(FirebaseFunctions)
@preconcurrency import FirebaseFunctions
import FirebaseCore
#endif

@MainActor
protocol VerifiedNumberDirectoryServicing {
    func publishOwnProfile(firstName: String, lastName: String) async throws
    func setOwnProfileVisibility(_ isVisible: Bool) async throws
    func lookup(number: String) async throws -> VerifiedNumberDirectoryLookup
}

enum VerifiedNumberDirectoryLookup: Equatable, Sendable {
    case found(PhoneOwner)
    case notRegistered
    case hidden
}

enum VerifiedNumberDirectoryError: LocalizedError, Equatable {
    case configurationMissing
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .configurationMissing:
            "Doğrulanmış numara dizini bu build için yapılandırılmamış."
        case .invalidResponse:
            "Doğrulanmış numara dizininden geçersiz bir yanıt alındı."
        }
    }
}

enum VerifiedNumberDirectoryFactory {
    @MainActor
    static func live() -> any VerifiedNumberDirectoryServicing {
#if canImport(FirebaseFunctions)
        if FirebaseApp.app() != nil {
            return FirebaseVerifiedNumberDirectoryService()
        }
#endif
        return DevelopmentVerifiedNumberDirectoryService()
    }
}

@MainActor
struct DevelopmentVerifiedNumberDirectoryService: VerifiedNumberDirectoryServicing {
    func publishOwnProfile(firstName: String, lastName: String) async throws {}
    func setOwnProfileVisibility(_ isVisible: Bool) async throws {}
    func lookup(number: String) async throws -> VerifiedNumberDirectoryLookup { .notRegistered }
}

#if canImport(FirebaseFunctions)
@MainActor
struct FirebaseVerifiedNumberDirectoryService: VerifiedNumberDirectoryServicing {
    private let functions = Functions.functions(region: "europe-west1")

    func publishOwnProfile(firstName: String, lastName: String) async throws {
        guard FirebaseApp.app() != nil else {
            throw VerifiedNumberDirectoryError.configurationMissing
        }

        _ = try await functions.httpsCallable("publishVerifiedProfile").call([
            "firstName": firstName,
            "lastName": lastName,
        ])
    }

    func setOwnProfileVisibility(_ isVisible: Bool) async throws {
        guard FirebaseApp.app() != nil else {
            throw VerifiedNumberDirectoryError.configurationMissing
        }

        _ = try await functions.httpsCallable("setVerifiedProfileVisibility").call([
            "isVisible": isVisible,
        ])
    }

    func lookup(number: String) async throws -> VerifiedNumberDirectoryLookup {
        guard FirebaseApp.app() != nil else {
            throw VerifiedNumberDirectoryError.configurationMissing
        }

        let result = try await functions.httpsCallable("lookupVerifiedProfile").call([
            "number": number,
        ])
        guard let payload = result.data as? [String: Any],
              let found = payload["found"] as? Bool else {
            throw VerifiedNumberDirectoryError.invalidResponse
        }
        guard found else {
            return payload["hidden"] as? Bool == true ? .hidden : .notRegistered
        }
        guard let owner = payload["owner"] as? [String: Any],
              let phoneNumber = owner["phoneNumber"] as? String,
              let displayName = owner["displayName"] as? String,
              let firstName = owner["firstName"] as? String,
              let lastName = owner["lastName"] as? String else {
            throw VerifiedNumberDirectoryError.invalidResponse
        }

        return .found(PhoneOwner(
            phoneNumber: phoneNumber,
            displayName: displayName,
            firstName: firstName,
            lastName: lastName
        ))
    }
}
#endif
