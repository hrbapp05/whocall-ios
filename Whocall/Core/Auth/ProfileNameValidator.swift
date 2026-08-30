import Foundation

enum ProfileNameField {
    case firstName
    case lastName

    var title: String {
        switch self {
        case .firstName: "Ad"
        case .lastName: "Soyad"
        }
    }
}

enum ProfileNameValidator {
    private static let namePattern = #"^[\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*(?: [\p{L}\p{M}]+(?:['’\-][\p{L}\p{M}]+)*)*$"#
    private static let reservedTerms: Set<String> = [
        "admin", "apple", "facebook", "google", "instagram", "meta", "tiktok", "whocall",
        "ad", "isim", "name", "soyad", "soyisim", "surname", "test", "deneme", "demo",
        "fake", "user", "kullanici", "unknown", "bilinmiyor", "yok", "yoktur",
        "abc", "abcd", "asdf", "asdfgh", "qwerty", "qwertyui", "xyz", "zxcv", "zxcvb"
    ]
    private static let blockedTerms: Set<String> = [
        "amk", "aq", "aptal", "gerizekali", "got", "ibne", "kahpe", "mal", "orospu",
        "pezevenk", "pic", "salak", "serefsiz", "sik", "siktir", "yavsak"
    ]

    static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .precomposedStringWithCanonicalMapping
    }

    static func validated(_ value: String, field: ProfileNameField) -> String? {
        validationMessage(for: value, field: field) == nil ? normalized(value) : nil
    }

    static func validationMessage(for value: String, field: ProfileNameField) -> String? {
        let name = normalized(value)
        let length = name.count
        if name.isEmpty {
            return "\(field.title) alanı boş bırakılamaz."
        }
        if length < 2 {
            return "\(field.title) en az 2 harf olmalıdır."
        }
        if length > 40 {
            return "\(field.title) en fazla 40 karakter olabilir."
        }
        if name.range(of: namePattern, options: .regularExpression) == nil {
            return "\(field.title) yalnızca harf, boşluk, kesme işareti veya kısa çizgi içerebilir."
        }

        let moderationValue = normalizedForModeration(name)
        let words = Set(moderationValue.split(separator: " ").map(String.init))
        let compact = moderationValue.replacingOccurrences(of: " ", with: "")
        if !words.isDisjoint(with: reservedTerms) || containsBlockedTerm(words: words, compact: compact) {
            return "Lütfen gerçek \(field.title.lowercased(with: Locale(identifier: "tr_TR"))) bilginizi girin."
        }
        if looksMeaningless(compact) {
            return "Lütfen geçerli bir \(field.title.lowercased(with: Locale(identifier: "tr_TR"))) girin."
        }
        return nil
    }

    private static func normalizedForModeration(_ value: String) -> String {
        value
            .lowercased(with: Locale(identifier: "tr_TR"))
            .folding(options: .diacriticInsensitive, locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
            .replacingOccurrences(of: #"[^a-z0-9]+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func containsBlockedTerm(words: Set<String>, compact: String) -> Bool {
        blockedTerms.contains { term in
            term.count <= 3 ? words.contains(term) : compact.contains(term)
        }
    }

    private static func looksMeaningless(_ compact: String) -> Bool {
        guard compact.count >= 2 else { return true }
        if Set(compact).count < 2 { return true }

        var previous: Character?
        var repeatedCount = 0
        for character in compact {
            if character == previous {
                repeatedCount += 1
                if repeatedCount >= 3 { return true }
            } else {
                previous = character
                repeatedCount = 1
            }
        }
        return false
    }
}
