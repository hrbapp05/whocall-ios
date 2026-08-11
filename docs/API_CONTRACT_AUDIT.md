# Live API Contract Audit

Audited: 2026-08-11  
Source: `https://whocallapp.online/openapi.json`

## Contract

- OpenAPI 3.1.0, API version 1.0.0.
- Staging base URL: `https://whocallapp.online`.
- Public operations: `GET /api/v1/health` and configuration-dependent `GET /api/v1/readiness`.
- Primary client operation: `GET /api/v1/phone/lookup?number=...`.
- Lookup authentication accepts either `X-API-Key` or an enabled Firebase bearer token.
- The client may send a UUID v4 `X-Request-Id`; the server returns the accepted/generated ID.

## Models implemented

- `PhoneLookupResponse` and `PhoneOwner` match the required success envelope.
- `APIErrorResponse`, `APIErrorPayload`, and `APIErrorCode` cover the canonical error envelope and codes.
- The request builder percent-encodes the `number` query and adds `Accept`, `X-Request-Id`, and a non-empty `X-API-Key`.

## Credential policy

The API base URL is committed because it is public configuration. The API key is deliberately empty in source control and must be injected by build configuration. No Firebase credential has been created.

