# Milestone 4 — Page 1 Fidelity and Store Integration

## Figma corrections

- Re-audited Page 1 nodes for the three onboarding screens and login.
- Replaced the app icon with the exported Page 1 app icon.
- Replaced the login center icon with its separate Page 1 asset.
- Rebuilt onboarding on the 402×874 Figma coordinate system, corrected sticker
  identities/positions, and preserved reduced-motion-safe entrance and floating
  motion.
- Replaced the lookup navigation-bar glass controls with explicit white Figma
  controls so iOS does not darken the back and credit surfaces.

## App Store Connect catalog

App: `WhoCall: Numara Sorgulama`  
Bundle ID: `com.levelappstudio.whocall`  
Apple app ID: `6800227705`  
Subscription group: `WhoCall Premium` (`22301730`)

| Type | Product ID | Apple ID | Türkiye price |
|---|---|---:|---:|
| Weekly subscription | `com.levelappstudio.whocall.premium.weekly` | 6800227814 | ₺499,99 |
| Monthly subscription | `com.levelappstudio.whocall.premium.monthly` | 6800228021 | ₺999,99 |
| 3 credits, consumable | `com.levelappstudio.whocall.credits.3` | 6800229373 | ₺199,99 |
| 5 credits, consumable | `com.levelappstudio.whocall.credits.5` | 6800229448 | ₺249,99 |
| 10 credits, consumable | `com.levelappstudio.whocall.credits.10` | 6800229596 | ₺499,99 |

All five products have Turkish localization, availability in all current
regions, and automatic availability in future regions. They remain in Apple's
normal `Prepare for Submission` state until submitted with the first app
version and review screenshots.

## RevenueCat integration

- RevenueCat iOS SDK 5.81.0 is pinned through Swift Package Manager.
- The custom Figma paywalls fetch localized App Store prices directly by the
  product identifiers above.
- Weekly/monthly purchase, 3/5/10 consumable purchase, customer-info updates,
  premium-state evaluation, credit balance updates, and restore are wired.
- The public SDK key is read from the ignored
  `REVENUECAT_PUBLIC_SDK_KEY` build setting. No key is committed.
- RevenueCat dashboard creation is pending because the signed-in account shows
  `You don't have permission to add app configurations.` Existing dashboard
  apps use other bundle identifiers and were intentionally not modified.

Once dashboard permission is granted, create an iOS app for
`com.levelappstudio.whocall`, import all five products, attach only the two
subscriptions to the `premium` entitlement, and create a default offering with
weekly and monthly packages. Consumable credits must not unlock the premium
entitlement.
