import Foundation

protocol AuthServicing: Sendable {
    func sendVerificationCode(to phoneNumber: String) async throws
    func verify(code: String) async throws
}

enum AuthError: LocalizedError, Equatable {
    case invalidPhoneNumber
    case invalidCode

    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber: "Geçerli bir telefon numarası girin."
        case .invalidCode: "Doğrulama kodu 5 haneli olmalıdır."
        }
    }
}

struct DevelopmentAuthService: AuthServicing {
    func sendVerificationCode(to phoneNumber: String) async throws {
        let digits = phoneNumber.filter(\.isNumber)
        guard digits.count == 10, digits.first == "5" else { throw AuthError.invalidPhoneNumber }
    }

    func verify(code: String) async throws {
        guard code.count == 5, code.allSatisfy(\.isNumber) else { throw AuthError.invalidCode }
    }
}

