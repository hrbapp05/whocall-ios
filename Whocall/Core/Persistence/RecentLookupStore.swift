import Foundation
import Observation

@MainActor
@Observable
final class RecentLookupStore {
    private(set) var records: [SearchRecord] = []

    private let defaults: UserDefaults
    private let storageKey = "whocall.recentLookups.v1"
    private var storedEntries: [StoredEntry] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func record(owner: PhoneOwner, contacts: ContactService) async {
        let canonicalNumber = owner.phoneNumber
        upsert(
            phoneNumber: canonicalNumber,
            displayName: owner.displayName,
            date: Date()
        )

        if let contactName = await contacts.displayName(for: canonicalNumber),
           !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            updateDisplayName(contactName, for: canonicalNumber)
        }
    }

    func clear() {
        storedEntries = []
        records = []
        defaults.removeObject(forKey: storageKey)
    }

    func remove(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) where storedEntries.indices.contains(index) {
            storedEntries.remove(at: index)
        }
        persist()
    }

    private func upsert(phoneNumber: String, displayName: String, date: Date) {
        storedEntries.removeAll { $0.phoneNumber == phoneNumber }
        storedEntries.insert(
            StoredEntry(
                id: UUID(),
                phoneNumber: phoneNumber,
                displayName: displayName,
                date: date
            ),
            at: 0
        )
        storedEntries = Array(storedEntries.prefix(20))
        persist()
    }

    private func updateDisplayName(_ displayName: String, for phoneNumber: String) {
        guard let index = storedEntries.firstIndex(where: { $0.phoneNumber == phoneNumber }) else { return }
        storedEntries[index].displayName = displayName
        persist()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([StoredEntry].self, from: data) else {
            records = []
            return
        }
        storedEntries = decoded.sorted { $0.date > $1.date }
        rebuildRecords()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(storedEntries) {
            defaults.set(data, forKey: storageKey)
        }
        rebuildRecords()
    }

    private func rebuildRecords() {
        records = storedEntries.map { entry in
            SearchRecord(
                id: entry.id,
                initials: initials(for: entry.displayName),
                phoneNumber: entry.phoneNumber,
                displayName: entry.displayName,
                time: formattedTime(entry.date)
            )
        }
    }

    private func initials(for displayName: String) -> String {
        let parts = displayName.split(separator: " ")
        let letters = parts.prefix(2).compactMap(\.first)
        let value = String(letters).uppercased(with: Locale(identifier: "tr_TR"))
        return value.isEmpty ? "?" : value
    }

    private func formattedTime(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "HH:mm"
            return "Dün \(formatter.string(from: date))"
        }
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}

private extension RecentLookupStore {
    struct StoredEntry: Codable {
        let id: UUID
        let phoneNumber: String
        var displayName: String
        let date: Date
    }
}
