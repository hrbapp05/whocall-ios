import Contacts
import Observation

@MainActor
@Observable
final class ContactService {
    private(set) var authorizationStatus: CNAuthorizationStatus
    private let store = CNContactStore()

    init() {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    var canReadContacts: Bool {
        Self.canReadContacts(with: authorizationStatus)
    }

    @discardableResult
    func requestAccessIfNeeded() async -> Bool {
        authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
        guard authorizationStatus == .notDetermined else { return canReadContacts }

        do {
            _ = try await store.requestAccess(for: .contacts)
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return canReadContacts
        } catch {
            authorizationStatus = CNContactStore.authorizationStatus(for: .contacts)
            return false
        }
    }

    func displayName(for phoneNumber: String) async -> String? {
        guard canReadContacts else { return nil }

        return await Task.detached(priority: .utility) {
            let store = CNContactStore()
            let keys: [CNKeyDescriptor] = [
                CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]
            let predicate = CNContact.predicateForContacts(
                matching: CNPhoneNumber(stringValue: phoneNumber)
            )
            guard let contact = try? store.unifiedContacts(
                matching: predicate,
                keysToFetch: keys
            ).first else {
                return nil
            }
            return CNContactFormatter.string(from: contact, style: .fullName)
        }.value
    }

    private static func canReadContacts(with status: CNAuthorizationStatus) -> Bool {
        if status == .authorized { return true }
        if #available(iOS 18.0, *), status == .limited { return true }
        return false
    }
}
