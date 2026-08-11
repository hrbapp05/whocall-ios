# WhoCall iOS

iOS 17+ SwiftUI client for WhoCall.

## Implemented scope

- Feature-first SwiftUI project skeleton
- Figma-sourced onboarding, authentication, home, lookup, result, person detail,
  community comments, history, premium, credits, and profile flows
- Shared semantic design system and exact exported Figma image assets
- Typed WhoCall API v1 models, error envelopes, and request client
- Credential-free authentication seam for later Firebase Auth wiring
- API credentials supplied outside source control

## Local setup

1. Open `Whocall.xcodeproj` in Xcode.
2. Copy `Config/Secrets.xcconfig.example` to `Config/Secrets.xcconfig` when a local API key is available.
3. Add that file to the target configuration in Xcode or inject `WHOCALL_API_KEY` through your build environment.

No Firebase credentials are included. The committed project does not contain an API key, phone dump, backend data, or PII.

## Validation

- Builds for an iPhone 17 Pro simulator with iOS 17+ deployment support.
- Core contract suite covers lookup request/response/error handling and the
  development authentication boundary.
- Visual simulator captures are kept out of source control under `outputs/`.

See `docs/MILESTONE_2_REPORT.md` for the current handoff and explicit production
integration boundaries.

The subsequent pixel-fidelity and motion correction pass is documented in
`docs/MILESTONE_3_FIGMA_FIDELITY.md`.
