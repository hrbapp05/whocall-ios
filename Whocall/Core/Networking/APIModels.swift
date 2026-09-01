import Foundation

struct PhoneLookupResponse: Decodable, Equatable, Sendable {
    let success: Bool
    let data: PhoneOwner
}

struct PhoneOwner: Decodable, Equatable, Hashable, Sendable {
    let phoneNumber: String
    let displayName: String
    let firstName: String
    let lastName: String

    var privacySafe: PhoneOwner {
        let safeName = PersonNameFormatter.privacySafeDisplayName(
            firstName: firstName,
            lastName: lastName,
            fallback: displayName
        )
        let parts = safeName.split(separator: " ")
        return PhoneOwner(
            phoneNumber: phoneNumber,
            displayName: safeName,
            firstName: parts.first.map(String.init) ?? safeName,
            lastName: parts.dropFirst().first.map(String.init) ?? ""
        )
    }
}

enum PhoneLookupOutcome: Equatable, Sendable {
    case found(PhoneOwner)
    case hidden
    case requesterHidden
    case notFound
}

enum PersonNameFormatter {
    private static let turkishLocale = Locale(identifier: "tr_TR")

    static func privacySafeDisplayName(
        firstName: String,
        lastName: String,
        fallback: String
    ) -> String {
        let cleanFirstName = cleaned(firstName)
        let cleanLastName = cleaned(lastName)

        if !cleanFirstName.isEmpty {
            return masked(firstName: cleanFirstName, lastName: cleanLastName)
        }
        return maskFullName(fallback)
    }

    static func maskFullName(_ fullName: String) -> String {
        let parts = cleaned(fullName)
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        guard let first = parts.first else { return "Bilinmeyen Kişi" }
        let lastPart = parts.dropFirst().last ?? ""
        if lastPart.count <= 2, lastPart.hasSuffix(".") {
            return "\(normalized(first)) \(lastPart.uppercased(with: turkishLocale))"
        }
        return masked(firstName: first, lastName: lastPart)
    }

    private static func masked(firstName: String, lastName: String) -> String {
        let normalizedFirstName = normalized(firstName)
        guard let lastInitial = lastName.first else { return normalizedFirstName }
        let normalizedInitial = String(lastInitial).uppercased(with: turkishLocale)
        return "\(normalizedFirstName) \(normalizedInitial)."
    }

    private static func normalized(_ value: String) -> String {
        value.lowercased(with: turkishLocale).capitalized(with: turkishLocale)
    }

    private static func cleaned(_ value: String) -> String {
        value
            .replacingOccurrences(of: " Olarak Biliniyor", with: "", options: [.caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct APIErrorResponse: Decodable, Equatable, Error, Sendable {
    let success: Bool
    let error: APIErrorPayload
    let requestId: UUID
}

struct APIErrorPayload: Decodable, Equatable, Sendable {
    let code: APIErrorCode
    let message: String
}

enum APIErrorCode: String, Decodable, Sendable {
    case invalidPhoneNumber = "INVALID_PHONE_NUMBER"
    case phoneNotFound = "PHONE_NOT_FOUND"
    case unauthorized = "UNAUTHORIZED"
    case forbidden = "FORBIDDEN"
    case rateLimited = "RATE_LIMITED"
    case methodNotAllowed = "METHOD_NOT_ALLOWED"
    case notFound = "NOT_FOUND"
    case databaseUnavailable = "DATABASE_UNAVAILABLE"
    case serviceUnavailable = "SERVICE_UNAVAILABLE"
    case internalError = "INTERNAL_ERROR"
}
