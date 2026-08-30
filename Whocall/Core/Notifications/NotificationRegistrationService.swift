import Foundation
import UIKit
import UserNotifications

#if canImport(FirebaseMessaging)
@preconcurrency import FirebaseFunctions
import FirebaseCore
import FirebaseMessaging
#endif

@MainActor
final class NotificationRegistrationService {
    static let shared = NotificationRegistrationService()

    private init() {}

    func requestAuthorizationAndRegister() async {
#if canImport(FirebaseMessaging)
        guard FirebaseApp.app() != nil else { return }
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
        guard authorized else { return }
        UIApplication.shared.registerForRemoteNotifications()
        if let token = try? await Messaging.messaging().token() {
            await register(token: token)
        }
#endif
    }

    func register(token: String) async {
#if canImport(FirebaseMessaging)
        guard FirebaseApp.app() != nil, !token.isEmpty else { return }
        do {
            _ = try await Functions.functions(region: "europe-west1")
                .httpsCallable("registerPushToken")
                .call(["token": token])
        } catch {
            // A refreshed FCM token is delivered again; a temporary outage is retried later.
        }
#endif
    }
}
