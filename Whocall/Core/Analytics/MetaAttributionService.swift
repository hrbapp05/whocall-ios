import AppTrackingTransparency
import AdSupport
import Foundation
import RevenueCat
import UIKit

#if canImport(FacebookCore)
@preconcurrency import FacebookCore
#endif

enum MetaAttributionConfiguration {
    static let appIDKey = "FacebookAppID"
    static let clientTokenKey = "FacebookClientToken"

    static func isConfigured(in bundle: Bundle = .main) -> Bool {
        isUsableClientValue(bundle.object(forInfoDictionaryKey: appIDKey) as? String) &&
        isUsableClientValue(bundle.object(forInfoDictionaryKey: clientTokenKey) as? String)
    }

    static func isUsableClientValue(_ value: String?) -> Bool {
        guard let value else { return false }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty &&
            !trimmed.contains("$(") &&
            !trimmed.lowercased().contains("replace")
    }
}

/// Coordinates Meta App Events and RevenueCat's server-to-server Meta Ads
/// integration. It deliberately never sends a searched number, profile name,
/// comment, tag, or lookup result to either advertising system.
@MainActor
final class MetaAttributionService {
    static let shared = MetaAttributionService()

    private var isMetaSDKConfigured = false
    private var isRevenueCatConfigured = false
    private var lastSynchronizedStatus: ATTrackingManager.AuthorizationStatus?

    private init() {}

    func configure(
        application: UIApplication,
        launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) {
#if canImport(FacebookCore)
        guard MetaAttributionConfiguration.isConfigured() else { return }

        // RevenueCat is the single source for purchase/subscription conversions.
        // Meta only receives activation signals directly from the device.
        Settings.shared.isAutoLogAppEventsEnabled = false
        Settings.shared.isAdvertiserIDCollectionEnabled = false
        _ = ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        isMetaSDKConfigured = true
#endif
    }

    func revenueCatDidConfigure() {
        isRevenueCatConfigured = true
        synchronizeCurrentAuthorization(force: true)
    }

    func requestAuthorizationIfNeeded() async {
        guard isMetaSDKConfigured else { return }

        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
        synchronizeCurrentAuthorization(force: true)
    }

    func applicationDidBecomeActive() {
        synchronizeCurrentAuthorization(force: false)
    }

    func trackPaywallPresented(section: String) {
#if canImport(FacebookCore)
        guard canLogFunnelEvents else { return }
        AppEvents.shared.logEvent(.viewedContent, parameters: [
            .contentType: "paywall",
            .contentID: section
        ])
#endif
    }

    func trackPaywallDismissed(section: String) {
#if canImport(FacebookCore)
        guard canLogFunnelEvents else { return }
        AppEvents.shared.logEvent(
            AppEvents.Name("whocall_paywall_dismissed"),
            parameters: [
                .contentType: "paywall",
                .contentID: section
            ]
        )
#endif
    }

    func trackCheckoutStarted(productID: String, productType: String) {
#if canImport(FacebookCore)
        guard canLogFunnelEvents else { return }
        AppEvents.shared.logEvent(.initiatedCheckout, parameters: [
            .contentID: productID,
            .contentType: productType,
            .numItems: 1
        ])
#endif
    }

#if canImport(FacebookCore)
    private var canLogFunnelEvents: Bool {
        isMetaSDKConfigured && ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
#endif

    private func synchronizeCurrentAuthorization(force: Bool) {
#if canImport(FacebookCore)
        guard isMetaSDKConfigured else { return }
        let status = ATTrackingManager.trackingAuthorizationStatus
        guard force || status != lastSynchronizedStatus else { return }
        lastSynchronizedStatus = status

        let isAuthorized = status == .authorized
        Settings.shared.isAdvertiserIDCollectionEnabled = isAuthorized

        guard isRevenueCatConfigured else { return }
        Purchases.shared.attribution.collectDeviceIdentifiers()

        // RevenueCat automatically maintains $attConsentStatus. Supplying the
        // Meta anonymous identifier only after authorization prevents CAPI
        // delivery for people who declined ATT.
        if isAuthorized {
            Purchases.shared.attribution.setFBAnonymousID(AppEvents.shared.anonymousID)
            AppEvents.shared.activateApp()
        }
#endif
    }
}
