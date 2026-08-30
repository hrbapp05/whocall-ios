import SwiftUI
import UIKit
import UserNotifications

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
#endif

final class AppDelegate: NSObject,
    UIApplicationDelegate,
    @preconcurrency UNUserNotificationCenterDelegate,
    @preconcurrency MessagingDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        MetaAttributionService.shared.configure(
            application: application,
            launchOptions: launchOptions
        )
#if canImport(FirebaseAuth)
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        if FirebaseApp.app() != nil {
            Auth.auth().languageCode = "tr"
            Messaging.messaging().delegate = self
            UNUserNotificationCenter.current().delegate = self
            application.registerForRemoteNotifications()
        }
#endif
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        MetaAttributionService.shared.applicationDidBecomeActive()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
#if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
#if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
#else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
#endif
        Messaging.messaging().apnsToken = deviceToken
#endif
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        Task { @MainActor in
            await NotificationRegistrationService.shared.register(token: fcmToken)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .badge, .sound]
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
#if canImport(FirebaseAuth)
        if FirebaseApp.app() != nil, Auth.auth().canHandleNotification(userInfo) {
            completionHandler(.noData)
            return
        }
#endif
        completionHandler(.noData)
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
#if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return false }
        return Auth.auth().canHandle(url)
#else
        return false
#endif
    }
}

@main
struct WhocallApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            AppRootView()
#if canImport(FirebaseAuth)
                .onOpenURL { url in
                    guard FirebaseApp.app() != nil else { return }
                    _ = Auth.auth().canHandle(url)
                }
#endif
        }
    }
}
