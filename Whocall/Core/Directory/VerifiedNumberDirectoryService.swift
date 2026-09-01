import Foundation

#if canImport(FirebaseFunctions)
@preconcurrency import FirebaseFunctions
import FirebaseCore
#endif

@MainActor
protocol VerifiedNumberDirectoryServicing {
    func publishOwnProfile(firstName: String, lastName: String) async throws
    func ownProfileVisibility() async throws -> VerifiedProfileVisibilityState
    func setOwnProfileVisibility(
        _ isVisible: Bool,
        confirmsCooldown: Bool
    ) async throws -> VerifiedProfileVisibilityState
    func lookup(number: String) async throws -> VerifiedNumberDirectoryLookup
}

struct VerifiedProfileVisibilityState: Equatable, Sendable {
    let isVisible: Bool
    let hideCount: Int
    let canEnableAt: Date?

    static let visible = Self(isVisible: true, hideCount: 0, canEnableAt: nil)

    var requiresHideConfirmation: Bool {
        isVisible && hideCount > 0
    }

    var isEnableLocked: Bool {
        guard !isVisible, let canEnableAt else { return false }
        return canEnableAt > Date()
    }
}

enum VerifiedNumberDirectoryLookup: Equatable, Sendable {
    case found(PhoneOwner)
    case notRegistered
    case hidden
    case suppressed
    case requesterHidden
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
    func ownProfileVisibility() async throws -> VerifiedProfileVisibilityState {
        .visible
    }
    func setOwnProfileVisibility(
        _ isVisible: Bool,
        confirmsCooldown: Bool
    ) async throws -> VerifiedProfileVisibilityState {
        .init(isVisible: isVisible, hideCount: isVisible ? 0 : 1, canEnableAt: nil)
    }
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

    func ownProfileVisibility() async throws -> VerifiedProfileVisibilityState {
        guard FirebaseApp.app() != nil else {
            throw VerifiedNumberDirectoryError.configurationMissing
        }

        let result = try await functions.httpsCallable("getOwnVerifiedProfileVisibility").call()
        return try visibilityState(from: result.data)
    }

    func setOwnProfileVisibility(
        _ isVisible: Bool,
        confirmsCooldown: Bool
    ) async throws -> VerifiedProfileVisibilityState {
        guard FirebaseApp.app() != nil else {
            throw VerifiedNumberDirectoryError.configurationMissing
        }

        let result = try await functions.httpsCallable("setVerifiedProfileVisibility").call([
            "isVisible": isVisible,
            "confirmsCooldown": confirmsCooldown,
        ])
        return try visibilityState(from: result.data)
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
            if payload["requesterHidden"] as? Bool == true { return .requesterHidden }
            if payload["suppressed"] as? Bool == true { return .suppressed }
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

    private func visibilityState(from value: Any) throws -> VerifiedProfileVisibilityState {
        guard let payload = value as? [String: Any],
              let isVisible = payload["isVisible"] as? Bool else {
            throw VerifiedNumberDirectoryError.invalidResponse
        }
        let hideCount = max(0, (payload["hideCount"] as? NSNumber)?.intValue ?? 0)
        let canEnableAt = (payload["canEnableAt"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
        return VerifiedProfileVisibilityState(
            isVisible: isVisible,
            hideCount: hideCount,
            canEnableAt: canEnableAt
        )
    }
}
#endif
