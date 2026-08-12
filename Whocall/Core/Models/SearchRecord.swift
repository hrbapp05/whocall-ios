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
