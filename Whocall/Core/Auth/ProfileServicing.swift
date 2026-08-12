import Foundation

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
#endif

@MainActor
protocol ProfileServicing {
    var currentUserID: String? { get }
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
    var currentUserID: String? { "development-user" }
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
    var currentUserID: String? { Auth.auth().currentUser?.uid }
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
            ProfileVisibilityPreference.setVisible(true, userID: user.uid)
            PendingVerifiedProfileStore.clear()
        } catch {
            // Profile creation must remain usable during a temporary Functions outage.
            // The app retries this verified, own-number publication on the next launch.
            PendingVerifiedProfileStore.save(firstName: firstName, lastName: lastName)
        }
    }
}
#endif

enum ProfileVisibilityPreference {
    private static let prefix = "whocall.profile.isVisible.v2"

    static func isVisible(userID: String?) -> Bool {
        guard let userID else { return true }
        let key = "\(prefix).\(userID)"
        guard UserDefaults.standard.object(forKey: key) != nil else { return true }
        return UserDefaults.standard.bool(forKey: key)
    }

    static func setVisible(_ isVisible: Bool, userID: String?) {
        guard let userID else { return }
        UserDefaults.standard.set(isVisible, forKey: "\(prefix).\(userID)")
    }

    static func clear(userID: String?) {
        guard let userID else { return }
        UserDefaults.standard.removeObject(forKey: "\(prefix).\(userID)")
    }
}

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

enum CurrentVerifiedProfileSynchronizer {
    /// Reconciles profiles created by earlier builds after Firebase Auth has
    /// refreshed the verified phone session. This makes the same directory
    /// result available to every signed-in account without using device-local
    /// contact data or exposing hidden profiles.
    @MainActor
    static func synchronize() async {
        let profile = ProfileServiceFactory.live()
        guard let userID = profile.currentUserID,
              profile.currentPhoneNumber?.isEmpty == false,
              let displayName = profile.currentDisplayName else { return }

        let parts = displayName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: \.isWhitespace)
        guard let firstName = parts.first, parts.count >= 2 else { return }
        let lastName = parts.dropFirst().joined(separator: " ")
        let isVisible = ProfileVisibilityPreference.isVisible(userID: userID)

        do {
            if isVisible {
                try await VerifiedNumberDirectoryFactory.live().publishOwnProfile(
                    firstName: String(firstName),
                    lastName: lastName
                )
            } else {
                try await VerifiedNumberDirectoryFactory.live().setOwnProfileVisibility(false)
            }
            PendingVerifiedProfileStore.clear()
        } catch {
            if isVisible {
                PendingVerifiedProfileStore.save(
                    firstName: String(firstName),
                    lastName: lastName
                )
            }
        }
    }
}
