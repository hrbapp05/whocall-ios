import SwiftUI
import UIKit

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
#endif

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
#if canImport(FirebaseAuth)
        if FirebaseApp.app() == nil,
           Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil {
            FirebaseApp.configure()
        }
        if FirebaseApp.app() != nil {
            application.registerForRemoteNotifications()
        }
#endif
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
#if canImport(FirebaseAuth)
        guard FirebaseApp.app() != nil else { return }
        Auth.auth().setAPNSToken(deviceToken, type: .unknown)
#endif
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
        }
    }
}
