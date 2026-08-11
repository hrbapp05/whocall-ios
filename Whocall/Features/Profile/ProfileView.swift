import SwiftUI

struct ProfileView: View {
    let onSignOut: () -> Void
    @State private var isVisible = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Text(profileInitials)
                            .font(.title2.weight(.bold))
                            .frame(width: 64, height: 64)
                            .background(DesignTokens.ColorToken.mint, in: .circle)
                        VStack(alignment: .leading) {
                            Text(displayName).font(.headline)
                            if let phoneNumber {
                                Text(phoneNumber).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Hesabım") {
                    Label("Numaramı Doğrula", systemImage: "checkmark.seal")
                    Toggle("Arama sonuçlarında görünürlük", isOn: $isVisible)
                    Label("Arayan Kimliği Uzantısı", systemImage: "phone.connection")
                }
                Section("Satın Alımlar") {
                    NavigationLink { PremiumView() } label: { Label("Aboneliklerim", systemImage: "crown") }
                    NavigationLink { CreditsView() } label: { Label("Kredi Alımlarım", systemImage: "creditcard") }
                }
                Section("Destek") {
                    Label("Bize Ulaşın", systemImage: "envelope")
                    Label("Gizlilik Politikası", systemImage: "lock.shield")
                    Label("Kullanım Koşulları", systemImage: "doc.text")
                }
                Button("Çıkış Yap", role: .destructive, action: onSignOut)
            }
            .navigationTitle("Profil")
        }
    }

    private var displayName: String {
        ProfileServiceFactory.live().currentDisplayName ?? "WhoCall Kullanıcısı"
    }

    private var phoneNumber: String? {
        ProfileServiceFactory.live().currentPhoneNumber
    }

    private var profileInitials: String {
        let letters = displayName.split(separator: " ").prefix(2).compactMap(\.first)
        let value = String(letters).uppercased(with: Locale(identifier: "tr_TR"))
        return value.isEmpty ? "W" : value
    }
}
