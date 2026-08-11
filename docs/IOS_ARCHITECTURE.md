# WhoCall iOS Architecture

## Application layers

- `App`: root session and lifecycle composition.
- `Features`: feature-first SwiftUI screens and local navigation flows.
- `Core/DesignSystem`: semantic colors, spacing, shapes, typography helpers,
  button style, and shared rows.
- `Core/Networking`: the live WhoCall v1 contract, request construction,
  decoding, request ID, and `X-API-Key` injection.
- `Core/Auth`: a credential-free authentication protocol plus a development
  implementation. This is the replacement point for Firebase Auth.
- `Core/Models`: local UI/domain records that never expose backend dumps.

## Navigation and state ownership

`AppRootView` owns the onboarding/authenticated boundary. `AppShellView` owns
the Home, History, and Profile tabs. Each feature owns its short-lived form and
navigation state; long-lived services are injected through initializers.

## Production integration boundaries

### WhoCall API

- Base URL: `https://whocallapp.online`
- Endpoint: `GET /api/v1/phone/lookup?number=...`
- Authentication: `X-API-Key` or Firebase bearer token according to the live
  OpenAPI contract.
- A real API key must be injected through an ignored local configuration or a
  secure CI secret. It must never be committed.

### Firebase

Firebase project credentials and `GoogleService-Info.plist` are intentionally
absent. A production adapter should conform to `AuthServicing`; the development
service is only a deterministic local seam for UI work and tests.

### Purchases

Premium and credit screens keep the Figma UI and use RevenueCat 5.81.0 for
localized products, purchase, customer info, and restore. The two subscription
products map to the `premium` entitlement; 3/5/10 credit products are
consumables and update the local balance only after a successful transaction.
The SDK public key is injected through `REVENUECAT_PUBLIC_SDK_KEY` and is never
committed. RevenueCat dashboard app/product/offering creation still requires an
account role that can add app configurations.
