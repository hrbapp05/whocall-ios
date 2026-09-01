import Contacts
import ContactsUI
import SwiftUI

struct NewContactDraft: Identifiable {
    let id = UUID()
    let name: String
    let phoneNumber: String
}

/// Presents Apple's user-controlled new-contact screen without reading the address book.
struct NewContactComposer: UIViewControllerRepresentable {
    let draft: NewContactDraft
    let onFinish: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }

    func makeUIViewController(context: Context) -> UINavigationController {
        let contact = CNMutableContact()
        let nameParts = draft.name.split(separator: " ", omittingEmptySubsequences: true)
        contact.givenName = nameParts.first.map(String.init) ?? draft.name
        contact.familyName = nameParts.dropFirst().map(String.init).joined(separator: " ")
        contact.phoneNumbers = [
            CNLabeledValue(
                label: CNLabelPhoneNumberMobile,
                value: CNPhoneNumber(stringValue: draft.phoneNumber)
            )
        ]

        let contactController = CNContactViewController(forNewContact: contact)
        contactController.delegate = context.coordinator
        return UINavigationController(rootViewController: contactController)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    final class Coordinator: NSObject, CNContactViewControllerDelegate {
        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func contactViewController(
            _ viewController: CNContactViewController,
            didCompleteWith contact: CNContact?
        ) {
            onFinish()
        }
    }
}
