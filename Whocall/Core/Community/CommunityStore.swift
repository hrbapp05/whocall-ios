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

    var errorDescription: String? {
        "Topluluk verileri güncellenemedi. Lütfen tekrar deneyin."
    }
}

@MainActor
@Observable
final class CommunityStore {
    private(set) var localComments: [String: [Comment]] = [:]
    private(set) var localTags: [String: [String]] = [:]
    private(set) var isLoading = false

    func comments(for phoneNumber: String) -> [Comment] {
        localComments[canonical(phoneNumber)] ?? []
    }

    func tags(for phoneNumber: String) -> [String] {
        localTags[canonical(phoneNumber)] ?? []
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
        } catch {
            // Keep the last successful snapshot on screen during a temporary outage.
        }
#endif
    }

    func addComment(_ body: String, for phoneNumber: String, author: String) async throws {
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBody.isEmpty else { return }
        let safeAuthor = PersonNameFormatter.maskFullName(author)

#if canImport(FirebaseFunctions)
        if FirebaseApp.app() != nil {
            _ = try await functions.httpsCallable("addNumberComment").call([
                "number": phoneNumber,
                "body": cleanBody,
                "author": safeAuthor,
            ])
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
        guard (2...24).contains(cleanTitle.count) else { return }

#if canImport(FirebaseFunctions)
        if FirebaseApp.app() != nil {
            _ = try await functions.httpsCallable("addNumberTag").call([
                "number": phoneNumber,
                "tag": cleanTitle,
            ])
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
        guard FirebaseApp.app() != nil else { return }
        _ = try await functions.httpsCallable("reportNumber").call([
            "number": phoneNumber,
            "reason": reason,
        ])
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
}
