import Foundation

#if canImport(FirebaseAuth)
@preconcurrency import FirebaseAuth
import FirebaseCore
#endif

protocol AuthServicing: Sendable {
    func sendVerificationCode(to phoneNumber: String) async throws -> String
    func verify(verificationID: String, code: String) async throws
}

enum AuthError: LocalizedError, Equatable {
    case invalidPhoneNumber
    case invalidCode
    case configurationMissing
    case expiredCode
    case tooManyRequests
    case networkUnavailable
    case appVerificationFailed
    case providerDisabled
    case smsQuotaExceeded
    case billingRequired
    case recaptchaCancelled
    case serviceFailure(code: Int)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            "Geçerli bir telefon numarası girin."
        case .invalidCode:
            "Doğrulama kodu 6 haneli olmalıdır."
        case .configurationMissing:
            "Telefon doğrulama servisi bu build için yapılandırılmamış."
        case .expiredCode:
            "Doğrulama kodunun süresi dolmuş. Lütfen yeni kod isteyin."
        case .tooManyRequests:
            "Güvenlik nedeniyle bu cihaz veya numara için yeni SMS istekleri geçici olarak durduruldu. Bu sınır Blaze planından bağımsızdır; lütfen bir süre bekleyin."
        case .networkUnavailable:
            "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."
        case .appVerificationFailed:
            "Uygulama doğrulaması tamamlanamadı. Lütfen tekrar deneyin."
        case .providerDisabled:
            "Telefonla giriş şu anda kullanılamıyor."
        case .smsQuotaExceeded:
            "SMS gönderim sınırına ulaşıldı. Lütfen daha sonra tekrar deneyin."
        case .billingRequired:
            "Gerçek SMS gönderebilmek için Firebase faturalandırmasının etkinleştirilmesi gerekiyor."
        case .recaptchaCancelled:
            "Uygulama doğrulama ekranı tamamlanmadı. Lütfen tekrar deneyin."
        case let .serviceFailure(code):
            "Doğrulama servisi isteği tamamlayamadı. Teknik kod: \(code)."
        case .verificationFailed:
            "Doğrulama tamamlanamadı. Lütfen bilgilerinizi kontrol edip tekrar deneyin."
        }
    }
}

enum PhoneVerificationRetryPolicy {
    static let tooManyRequestsCooldown: TimeInterval = 15 * 60

    static func cooldown(for error: AuthError) -> TimeInterval? {
        error == .tooManyRequests ? tooManyRequestsCooldown : nil
    }
}

enum AuthServiceFactory {
    static func live() -> any AuthServicing {
#if canImport(FirebaseAuth)
        FirebasePhoneAuthService()
#else
        DevelopmentAuthService()
#endif
    }
}

struct DevelopmentAuthService: AuthServicing {
    func sendVerificationCode(to phoneNumber: String) async throws -> String {
        let digits = phoneNumber.filter(\.isNumber)
        guard digits.count == 12, digits.hasPrefix("90"), digits.dropFirst(2).first == "5" else {
            throw AuthError.invalidPhoneNumber
        }
        return "development-verification"
    }

    func verify(verificationID: String, code: String) async throws {
        guard !verificationID.isEmpty, code.count == 6, code.allSatisfy(\.isNumber) else {
            throw AuthError.invalidCode
        }
    }
}

#if canImport(FirebaseAuth)
struct FirebasePhoneAuthService: AuthServicing, @unchecked Sendable {
    func sendVerificationCode(to phoneNumber: String) async throws -> String {
        guard FirebaseApp.app() != nil else { throw AuthError.configurationMissing }
        let digits = phoneNumber.filter(\.isNumber)
        guard digits.count == 12, digits.hasPrefix("90"), digits.dropFirst(2).first == "5" else {
            throw AuthError.invalidPhoneNumber
        }

        Auth.auth().languageCode = "tr"
        return try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber("+\(digits)", uiDelegate: nil) { verificationID, error in
                if let error {
                    continuation.resume(throwing: Self.localized(error))
                } else if let verificationID {
                    continuation.resume(returning: verificationID)
                } else {
                    continuation.resume(throwing: AuthError.configurationMissing)
                }
            }
        }
    }

    func verify(verificationID: String, code: String) async throws {
        guard code.count == 6, code.allSatisfy(\.isNumber) else { throw AuthError.invalidCode }
        guard FirebaseApp.app() != nil else { throw AuthError.configurationMissing }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code
        )
        do {
            _ = try await Auth.auth().signIn(with: credential)
        } catch {
            throw Self.localized(error)
        }
    }

    static func localized(_ error: Error) -> AuthError {
        let nsError = error as NSError
        let firebaseErrorName = nsError.userInfo[AuthErrorUserInfoNameKey] as? String ?? ""
        let failureReason = nsError.userInfo[NSLocalizedFailureReasonErrorKey] as? String ?? ""
        let serverSignal = "\(firebaseErrorName) \(failureReason) \(nsError.localizedDescription)"
            .uppercased()

        if serverSignal.contains("BILLING") || serverSignal.contains("PAYMENT_REQUIRED") {
            return .billingRequired
        }

        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
            let mappedUnderlying = localized(underlying)
            if mappedUnderlying != .verificationFailed,
               mappedUnderlying != .serviceFailure(code: (underlying as NSError).code) {
                return mappedUnderlying
            }
        }

        return switch nsError.code {
        case AuthErrorCode.invalidPhoneNumber.rawValue,
             AuthErrorCode.missingPhoneNumber.rawValue:
            .invalidPhoneNumber
        case AuthErrorCode.invalidVerificationCode.rawValue,
             AuthErrorCode.missingVerificationCode.rawValue,
             AuthErrorCode.invalidCredential.rawValue:
            .invalidCode
        case AuthErrorCode.sessionExpired.rawValue,
             AuthErrorCode.invalidVerificationID.rawValue,
             AuthErrorCode.missingVerificationID.rawValue:
            .expiredCode
        case AuthErrorCode.tooManyRequests.rawValue:
            .tooManyRequests
        case AuthErrorCode.quotaExceeded.rawValue:
            .smsQuotaExceeded
        case AuthErrorCode.networkError.rawValue,
             AuthErrorCode.webNetworkRequestFailed.rawValue:
            .networkUnavailable
        case AuthErrorCode.operationNotAllowed.rawValue:
            .providerDisabled
        case AuthErrorCode.appNotAuthorized.rawValue,
             AuthErrorCode.invalidAPIKey.rawValue,
             AuthErrorCode.invalidClientID.rawValue,
             AuthErrorCode.missingClientIdentifier.rawValue:
            .configurationMissing
        case AuthErrorCode.missingAppCredential.rawValue,
             AuthErrorCode.invalidAppCredential.rawValue,
             AuthErrorCode.missingAppToken.rawValue,
             AuthErrorCode.notificationNotForwarded.rawValue,
             AuthErrorCode.appNotVerified.rawValue,
             AuthErrorCode.captchaCheckFailed.rawValue,
             AuthErrorCode.appVerificationUserInteractionFailure.rawValue,
             AuthErrorCode.webContextAlreadyPresented.rawValue,
             AuthErrorCode.webInternalError.rawValue,
             AuthErrorCode.recaptchaNotEnabled.rawValue,
             AuthErrorCode.missingRecaptchaToken.rawValue,
             AuthErrorCode.invalidRecaptchaToken.rawValue,
             AuthErrorCode.invalidRecaptchaAction.rawValue,
             AuthErrorCode.missingClientType.rawValue,
             AuthErrorCode.missingRecaptchaVersion.rawValue,
             AuthErrorCode.invalidRecaptchaVersion.rawValue,
             AuthErrorCode.invalidReqType.rawValue,
             AuthErrorCode.recaptchaSDKNotLinked.rawValue,
             AuthErrorCode.recaptchaSiteKeyMissing.rawValue,
             AuthErrorCode.recaptchaActionCreationFailed.rawValue:
            .appVerificationFailed
        case AuthErrorCode.webContextCancelled.rawValue:
            .recaptchaCancelled
        default:
            .serviceFailure(code: nsError.code)
        }
    }
}
#endif
