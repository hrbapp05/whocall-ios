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

        do {
            try await VerifiedNumberDirectoryFactory.live().publishOwnProfile(
                firstName: firstName,
                lastName: lastName
            )
            PendingVerifiedProfileStore.clear()
        } catch {
            // Profile creation must remain usable during a temporary Functions outage.
            // The app retries this verified, own-number publication on the next launch.
            PendingVerifiedProfileStore.save(firstName: firstName, lastName: lastName)
        }
    }
}
#endif

enum PendingVerifiedProfileStore {
    private static let firstNameKey = "whocall.directory.pendingFirstName"
    private static let lastNameKey = "whocall.directory.pendingLastName"

    static func save(firstName: String, lastName: String) {
        UserDefaults.standard.set(firstName, forKey: firstNameKey)
        UserDefaults.standard.set(lastName, forKey: lastNameKey)
    }

    @MainActor
    static func retryIfNeeded() async {
        guard let firstName = UserDefaults.standard.string(forKey: firstNameKey),
              let lastName = UserDefaults.standard.string(forKey: lastNameKey) else { return }
        do {
            try await VerifiedNumberDirectoryFactory.live().publishOwnProfile(
                firstName: firstName,
                lastName: lastName
            )
            clear()
        } catch {
            // Keep the pending profile for the next authenticated launch.
        }
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: firstNameKey)
        UserDefaults.standard.removeObject(forKey: lastNameKey)
    }
}
