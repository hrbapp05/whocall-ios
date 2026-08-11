import Foundation

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
#endif

@MainActor
protocol ProfileServicing {
    var currentDisplayName: String? { get }
    var currentPhoneNumber: String? { get }
    func updateProfile(firstName: String, lastName: String) async throws
}

enum ProfileServiceFactory {
    @MainActor
    static func live() -> any ProfileServicing {
#if canImport(FirebaseAuth)
        if FirebaseApp.app() != nil, Auth.auth().currentUser != nil {
            return FirebaseProfileService()
        }
#endif
        return DevelopmentProfileService()
    }
}

@MainActor
struct DevelopmentProfileService: ProfileServicing {
    var currentDisplayName: String? {
        UserDefaults.standard.string(forKey: "whocall.profile.displayName")
    }
    var currentPhoneNumber: String? { nil }

    func updateProfile(firstName: String, lastName: String) async throws {
        UserDefaults.standard.set(
            "\(firstName) \(lastName)",
            forKey: "whocall.profile.displayName"
        )
    }
}

#if canImport(FirebaseAuth)
@MainActor
struct FirebaseProfileService: ProfileServicing {
    var currentDisplayName: String? { Auth.auth().currentUser?.displayName }
    var currentPhoneNumber: String? { Auth.auth().currentUser?.phoneNumber }

    func updateProfile(firstName: String, lastName: String) async throws {
        guard let user = Auth.auth().currentUser else { throw AuthError.configurationMissing }
        let request = user.createProfileChangeRequest()
        request.displayName = "\(firstName) \(lastName)"
        try await request.commitChanges()
    }
}
#endif
