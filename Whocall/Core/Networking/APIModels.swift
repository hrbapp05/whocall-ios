import Foundation

struct PhoneLookupResponse: Decodable, Equatable, Sendable {
    let success: Bool
    let data: PhoneOwner
}

struct PhoneOwner: Decodable, Equatable, Sendable {
    let phoneNumber: String
    let displayName: String
    let firstName: String
    let lastName: String
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

