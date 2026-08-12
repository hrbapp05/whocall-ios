import Foundation
import Observation

#if canImport(FirebaseFunctions)
@preconcurrency import FirebaseFunctions
import FirebaseCore
#endif

struct Comment: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let initial: String
    let author: String
    let body: String
    let time: String

    init(
        id: String = UUID().uuidString,
        initial: String,
        author: String,
        body: String,
        time: String
    ) {
        self.id = id
        self.initial = initial
        self.author = author
        self.body = body
        self.time = time
    }
}

enum CommunityStoreError: LocalizedError {
    case invalidResponse
    case invalidContent
    case blockedLanguage
    case authenticationRequired
    case tooManyRequests
    case serviceUnavailable

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Topluluk verileri güncellenemedi. Lütfen tekrar deneyin."
        case .invalidContent:
            "İçeriğin uzunluğunu ve biçimini kontrol edin."
        case .blockedLanguage:
            "Küfür veya hakaret içeren içerikler gönderilemez."
        case .authenticationRequired:
            "Bu işlem için telefon doğrulamasıyla yeniden giriş yapın."
        case .tooManyRequests:
            "Çok fazla işlem yaptınız. Lütfen kısa bir süre sonra tekrar deneyin."
        case .serviceUnavailable:
            "Topluluk servisine ulaşılamıyor. Lütfen tekrar deneyin."
        }
    }
}

enum CommunityTrustLevel: Equatable, Sendable {
    case high
    case medium
    case risky

    init(reportCount: Int) {
        if reportCount > 20 { self = .risky }
        else if reportCount >= 3 { self = .medium }
        else { self = .high }
    }
}

enum CommunityContentModerator {
    private static let blockedTerms = [
        "amk", "aq", "orospu", "sik", "siktir", "piç", "pic", "yavşak", "yavsak",
        "şerefsiz", "serefsiz", "gerizekalı", "gerizekali", "salak", "aptal", "ibne",
        "kahpe", "pezevenk", "göt", "got", "bok", "mal"
    ]

    static func containsBlockedLanguage(_ value: String) -> Bool {
        let normalized = normalize(value)
        let compact = normalized.replacingOccurrences(of: " ", with: "")
        let words = Set(normalized.split(separator: " ").map(String.init))
        return blockedTerms.contains { term in
            let cleanTerm = normalize(term).replacingOccurrences(of: " ", with: "")
            return cleanTerm.count <= 3 ? words.contains(cleanTerm) : compact.contains(cleanTerm)
        }
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .lowercased(with: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

@MainActor
@Observable
final class CommunityStore {
    private(set) var localComments: [String: [Comment]] = [:]
    private(set) var localTags: [String: [String]] = [:]
    private(set) var localReportCounts: [String: Int] = [:]
    private(set) var isLoading = false

    func comments(for phoneNumber: String) -> [Comment] {
        localComments[canonical(phoneNumber)] ?? []
    }

    func tags(for phoneNumber: String) -> [String] {
        localTags[canonical(phoneNumber)] ?? []
    }

    func reportCount(for phoneNumber: String) -> Int {
        localReportCounts[canonical(phoneNumber)] ?? 0
    }

    func trustLevel(for phoneNumber: String) -> CommunityTrustLevel {
        CommunityTrustLevel(reportCount: reportCount(for: phoneNumber))
    }

    func refresh(for phoneNumber: String) async {
#if canImport(FirebaseFunctions)
        guard FirebaseApp.app() != nil else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await functions.httpsCallable("getNumberCommunity").call([
                "number": phoneNumber,
            ])
            guard let payload = result.data as? [String: Any] else {
                throw CommunityStoreError.invalidResponse
            }
            let key = canonical(phoneNumber)
            localTags[key] = (payload["tags"] as? [String] ?? []).sorted(by: localizedSort)
            localComments[key] = parseComments(payload["comments"] as? [[String: Any]] ?? [])
            localReportCounts[key] = payload["reportCount"] as? Int ?? 0
        } catch {
            // Keep the last successful snapshot on screen during a temporary outage.
        }
#endif
    }

    func addComment(_ body: String, for phoneNumber: String, author: String) async throws {
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...500).contains(cleanBody.count) else { throw CommunityStoreError.invalidContent }
        guard !CommunityContentModerator.containsBlockedLanguage(cleanBody) else {
            throw CommunityStoreError.blockedLanguage
        }
        let safeAuthor = PersonNameFormatter.maskFullName(author)

#if canImport(FirebaseFunctions)
        if FirebaseApp.app() != nil {
            do {
                _ = try await functions.httpsCallable("addNumberComment").call([
                    "number": phoneNumber,
                    "body": cleanBody,
                    "author": safeAuthor,
                ])
            } catch {
                throw localized(error)
            }
            await refresh(for: phoneNumber)
            return
        }
#endif

        let entry = Comment(
            initial: String(safeAuthor.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")),
            author: safeAuthor,
            body: cleanBody,
            time: "Şimdi"
        )
        localComments[canonical(phoneNumber), default: []].insert(entry, at: 0)
    }

    func addTag(_ title: String, for phoneNumber: String) async throws {
        let cleanTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard (2...24).contains(cleanTitle.count) else { throw CommunityStoreError.invalidContent }
        guard !CommunityContentModerator.containsBlockedLanguage(cleanTitle) else {
            throw CommunityStoreError.blockedLanguage
        }

#if canImport(FirebaseFunctions)
        if FirebaseApp.app() != nil {
            do {
                _ = try await functions.httpsCallable("addNumberTag").call([
                    "number": phoneNumber,
                    "tag": cleanTitle,
                ])
            } catch {
                throw localized(error)
            }
            await refresh(for: phoneNumber)
            return
        }
#endif

        let key = canonical(phoneNumber)
        if !localTags[key, default: []].contains(where: { $0.caseInsensitiveCompare(cleanTitle) == .orderedSame }) {
            localTags[key, default: []].append(cleanTitle)
            localTags[key]?.sort(by: localizedSort)
        }
    }

    func report(phoneNumber: String, reason: String) async throws {
#if canImport(FirebaseFunctions)
        guard FirebaseApp.app() != nil else { throw CommunityStoreError.serviceUnavailable }
        do {
            let result = try await functions.httpsCallable("reportNumber").call([
                "number": phoneNumber,
                "reason": reason,
            ])
            if let payload = result.data as? [String: Any], let reportCount = payload["reportCount"] as? Int {
                localReportCounts[canonical(phoneNumber)] = reportCount
            } else {
                await refresh(for: phoneNumber)
            }
        } catch {
            throw localized(error)
        }
#endif
    }

    private var functions: Functions {
#if canImport(FirebaseFunctions)
        Functions.functions(region: "europe-west1")
#else
        fatalError("Firebase Functions is unavailable")
#endif
    }

    private func parseComments(_ values: [[String: Any]]) -> [Comment] {
        values.compactMap { value in
            guard let id = value["id"] as? String,
                  let author = value["author"] as? String,
                  let body = value["body"] as? String,
                  let time = value["time"] as? String else { return nil }
            return Comment(
                id: id,
                initial: String(author.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")),
                author: PersonNameFormatter.maskFullName(author),
                body: body,
                time: time
            )
        }
    }

    private func canonical(_ number: String) -> String {
        String(number.filter(\.isNumber).suffix(10))
    }

    private func localizedSort(_ lhs: String, _ rhs: String) -> Bool {
        lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }

    private func localized(_ error: Error) -> CommunityStoreError {
#if canImport(FirebaseFunctions)
        let value = error as NSError
        guard value.domain == FunctionsErrorDomain,
              let code = FunctionsErrorCode(rawValue: value.code) else { return .serviceUnavailable }
        switch code {
        case .unauthenticated, .failedPrecondition:
            return .authenticationRequired
        case .invalidArgument:
            return value.localizedDescription.localizedCaseInsensitiveContains("küfür") ||
                value.localizedDescription.localizedCaseInsensitiveContains("hakaret")
                ? .blockedLanguage : .invalidContent
        case .resourceExhausted:
            return .tooManyRequests
        default:
            return .serviceUnavailable
        }
#else
        return .serviceUnavailable
#endif
    }
}
