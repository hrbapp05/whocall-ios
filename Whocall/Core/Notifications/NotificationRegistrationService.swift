import Foundation
import UIKit
import UserNotifications

#if canImport(FirebaseMessaging)
@preconcurrency import FirebaseFunctions
import FirebaseCore
import FirebaseMessaging
#endif

enum NotificationAuthorizationState: Equatable, Sendable {
    case notDetermined
    case enabled
    case denied
    case unavailable

    var isAuthorized: Bool {
        self == .enabled
    }

    var title: String {
        switch self {
        case .notDetermined: "Henüz izin verilmedi"
        case .enabled: "Bildirimler açık"
        case .denied: "iPhone ayarlarından kapalı"
        case .unavailable: "Şu anda kullanılamıyor"
        }
    }
}

enum NotificationPreference {
    private static let keyPrefix = "notificationsEnabled.v1."

    static func isEnabled(userID: String?, defaults: UserDefaults = .standard) -> Bool {
        guard let userID, !userID.isEmpty else { return false }
        let key = keyPrefix + userID
        guard defaults.object(forKey: key) != nil else { return true }
        return defaults.bool(forKey: key)
    }

    static func setEnabled(_ enabled: Bool, userID: String?, defaults: UserDefaults = .standard) {
        guard let userID, !userID.isEmpty else { return }
        defaults.set(enabled, forKey: keyPrefix + userID)
    }

    static func clear(userID: String?, defaults: UserDefaults = .standard) {
        guard let userID, !userID.isEmpty else { return }
        defaults.removeObject(forKey: keyPrefix + userID)
    }
}

@MainActor
final class NotificationRegistrationService {
    static let shared = NotificationRegistrationService()

    private init() {}

    @discardableResult
    func requestAuthorizationAndRegister() async -> NotificationAuthorizationState {
#if canImport(FirebaseMessaging)
        let userID = ProfileServiceFactory.live().currentUserID
        guard FirebaseApp.app() != nil,
              NotificationPreference.isEnabled(userID: userID) else {
            return await authorizationState()
        }
        Messaging.messaging().isAutoInitEnabled = true
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let authorized: Bool
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            authorized = true
        case .notDetermined:
            authorized = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) == true
        case .denied:
            authorized = false
        @unknown default:
            authorized = false
        }
        guard authorized else { return await authorizationState() }
        UIApplication.shared.registerForRemoteNotifications()
        if let token = try? await Messaging.messaging().token() {
            await register(token: token)
        }
        return .enabled
#else
        return await authorizationState()
#endif
    }

    func authorizationState() async -> NotificationAuthorizationState {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return switch settings.authorizationStatus {
        case .notDetermined: .notDetermined
        case .authorized, .provisional, .ephemeral: .enabled
        case .denied: .denied
        @unknown default: .unavailable
        }
    }

    @discardableResult
    func setEnabled(_ enabled: Bool) async -> NotificationAuthorizationState {
        let userID = ProfileServiceFactory.live().currentUserID
        NotificationPreference.setEnabled(enabled, userID: userID)
        if enabled {
            return await requestAuthorizationAndRegister()
        }

#if canImport(FirebaseMessaging)
        if FirebaseApp.app() != nil,
           let token = try? await Messaging.messaging().token() {
            await unregister(token: token)
        }
        Messaging.messaging().isAutoInitEnabled = false
        try? await Messaging.messaging().deleteToken()
#endif
        UIApplication.shared.unregisterForRemoteNotifications()
        return await authorizationState()
    }

    func register(token: String) async {
#if canImport(FirebaseMessaging)
        let userID = ProfileServiceFactory.live().currentUserID
        guard FirebaseApp.app() != nil,
              !token.isEmpty,
              NotificationPreference.isEnabled(userID: userID) else { return }
        do {
            _ = try await Functions.functions(region: "europe-west1")
                .httpsCallable("registerPushToken")
                .call(["token": token])
        } catch {
            // A refreshed FCM token is delivered again; a temporary outage is retried later.
        }
#endif
    }

    private func unregister(token: String) async {
#if canImport(FirebaseMessaging)
        guard FirebaseApp.app() != nil, !token.isEmpty else { return }
        do {
            _ = try await Functions.functions(region: "europe-west1")
                .httpsCallable("unregisterPushToken")
                .call(["token": token])
        } catch {
            // The local preference still prevents this token from being re-registered.
        }
#endif
    }
}
