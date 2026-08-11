import Foundation

struct SearchRecord: Identifiable, Hashable, Sendable {
    let id: UUID
    let initials: String
    let phoneNumber: String
    let displayName: String
    let time: String
    let isWarning: Bool

    init(
        id: UUID = UUID(),
        initials: String,
        phoneNumber: String,
        displayName: String,
        time: String,
        isWarning: Bool = false
    ) {
        self.id = id
        self.initials = initials
        self.phoneNumber = phoneNumber
        self.displayName = displayName
        self.time = time
        self.isWarning = isWarning
    }
}

enum PreviewData {
    static let records = [
        SearchRecord(initials: "CC", phoneNumber: "+1 (347) 908-2245", displayName: "Mert Deniz", time: "20:45"),
        SearchRecord(initials: "!", phoneNumber: "+44 (730) 119-842", displayName: "Potansiyel Scam", time: "Dün 12:15", isWarning: true),
        SearchRecord(initials: "M", phoneNumber: "+61 (452) 779-603", displayName: "Mia C. Olarak Biliniyor", time: "Dün"),
        SearchRecord(initials: "T", phoneNumber: "+61 (452) 779-603", displayName: "Teddy H. Olarak Biliniyor", time: "16:35")
    ]
}

