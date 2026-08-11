# WhoCall iOS

iOS 17+ SwiftUI client for WhoCall.

## Current milestone

- Feature-first SwiftUI project skeleton
- Figma-sourced three-page onboarding flow
- Typed WhoCall API v1 models and request builder
- API credentials supplied outside source control

## Local setup

1. Open `Whocall.xcodeproj` in Xcode.
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` when a local API key is available.
3. Add that file to the target configuration in Xcode or inject `WHOCALL_API_KEY` through your build environment.

No Firebase credentials are included. The committed project does not contain an API key, phone dump, backend data, or PII.

