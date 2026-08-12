import Foundation
import Observation

struct Comment: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let initial: String
    let author: String
    let body: String
    let time: String

    init(
        id: UUID = UUID(),
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

    static let sample = [
        Comment(initial: "M", author: "Mehmet K.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "A", author: "Ahmet S.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "E", author: "Elif Y.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "F", author: "Fatma G.", body: "Kendisini çok yakından tanırız. Gayet güvenilir ve iyi bir insan.", time: "Dün"),
        Comment(initial: "B", author: "Burak T.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "Z", author: "Zeynep A.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "C", author: "Cem D.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "A", author: "Ayşe K.", body: "Kendisini çok yakından tanırız. Gayet güvenilir ve iyi bir insan.", time: "Dün"),
        Comment(initial: "E", author: "Emre B.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "D", author: "Deniz P.", body: "Uzun zamandır tanıyorum, güvenilir biridir", time: "2 gün"),
        Comment(initial: "S", author: "Selin M.", body: "İletişimi iyi ve yardımsever bir kişi", time: "2 gün"),
        Comment(initial: "O", author: "Okan R.", body: "Aynı mahallede oturuyoruz", time: "3 gün")
    ]
}

struct CommunityReport: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let phoneNumber: String
    let reason: String
    let createdAt: Date
}

@MainActor
@Observable
final class CommunityStore {
    private(set) var localComments: [String: [Comment]] = [:]
    private(set) var reports: [CommunityReport] = []

    private let defaults: UserDefaults
    private let commentsKey = "whocall.communityComments.v1"
    private let reportsKey = "whocall.communityReports.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func comments(for phoneNumber: String) -> [Comment] {
        (localComments[canonical(phoneNumber)] ?? []) + Comment.sample
    }

    func addComment(_ body: String, for phoneNumber: String, author: String) {
        let cleanBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanBody.isEmpty else { return }
        let safeAuthor = PersonNameFormatter.maskFullName(author)
        let entry = Comment(
            initial: String(safeAuthor.prefix(1)).uppercased(with: Locale(identifier: "tr_TR")),
            author: safeAuthor,
            body: cleanBody,
            time: "Şimdi"
        )
        localComments[canonical(phoneNumber), default: []].insert(entry, at: 0)
        persist(localComments, key: commentsKey)
    }

    func report(phoneNumber: String, reason: String) {
        reports.append(
            CommunityReport(
                id: UUID(),
                phoneNumber: canonical(phoneNumber),
                reason: reason,
                createdAt: Date()
            )
        )
        persist(reports, key: reportsKey)
    }

    private func load() {
        localComments = decode([String: [Comment]].self, key: commentsKey) ?? [:]
        reports = decode([CommunityReport].self, key: reportsKey) ?? []
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    private func decode<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func canonical(_ number: String) -> String {
        String(number.filter(\.isNumber).suffix(10))
    }
}
