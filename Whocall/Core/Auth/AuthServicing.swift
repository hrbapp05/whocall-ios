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
            "Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin."
        case .networkUnavailable:
            "İnternet bağlantısı kurulamadı. Bağlantınızı kontrol edip tekrar deneyin."
        case .appVerificationFailed:
            "Uygulama doğrulaması tamamlanamadı. Lütfen tekrar deneyin."
        case .providerDisabled:
            "Telefonla giriş şu anda kullanılamıyor."
        case .smsQuotaExceeded:
            "SMS gönderim sınırına ulaşıldı. Lütfen daha sonra tekrar deneyin."
        case .verificationFailed:
            "Doğrulama tamamlanamadı. Lütfen bilgilerinizi kontrol edip tekrar deneyin."
        }
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

    private static func localized(_ error: Error) -> AuthError {
        switch (error as NSError).code {
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
             AuthErrorCode.invalidAPIKey.rawValue:
            .configurationMissing
        case AuthErrorCode.missingAppCredential.rawValue,
             AuthErrorCode.invalidAppCredential.rawValue,
             AuthErrorCode.missingAppToken.rawValue,
             AuthErrorCode.notificationNotForwarded.rawValue,
             AuthErrorCode.appNotVerified.rawValue,
             AuthErrorCode.captchaCheckFailed.rawValue,
             AuthErrorCode.appVerificationUserInteractionFailure.rawValue:
            .appVerificationFailed
        default:
            .verificationFailed
        }
    }
}
#endif
