import SwiftUI
import UIKit

struct ProfileView: View {
    let onSignOut: () -> Void
    @AppStorage("whocall.profile.isVisible") private var isVisible = true
    @State private var isPhoneVerificationPresented = false
    @State private var isCallerIDInfoPresented = false
    @State private var verificationMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Text(profileInitials)
                            .font(.title2.weight(.bold))
                            .frame(width: 64, height: 64)
                            .background(DesignTokens.ColorToken.mint, in: .circle)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(displayName).font(.headline)
                            if let phoneNumber {
                                Label(formattedPhoneNumber(phoneNumber), systemImage: "checkmark.seal.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(DesignTokens.ColorToken.success)
                            }
                        }
                    }
                }

                Section("Hesabım") {
                    Button(action: verifyPhoneNumber) {
                        HStack {
                            Label("Numaramı Doğrula", systemImage: "checkmark.seal")
                            Spacer()
                            if phoneNumber != nil {
                                Text("Doğrulandı")
                                    .font(.caption)
                                    .foregroundStyle(DesignTokens.ColorToken.success)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    Toggle("Arama sonuçlarında görünürlük", isOn: $isVisible)

                    Button {
                        isCallerIDInfoPresented = true
                    } label: {
                        HStack {
                            Label("Arayan Kimliği Uzantısı", systemImage: "phone.connection")
                            Spacer()
                            Text("Bilgi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)
                }

                Section("Satın Alımlar") {
                    NavigationLink { PremiumView() } label: {
                        Label("Aboneliklerim", systemImage: "crown")
                    }
                    NavigationLink { CreditsView() } label: {
                        Label("Kredi Alımlarım", systemImage: "creditcard")
                    }
                }

                Section("Destek") {
                    Label("Bize Ulaşın", systemImage: "envelope")
                    Label("Gizlilik Politikası", systemImage: "lock.shield")
                    Label("Kullanım Koşulları", systemImage: "doc.text")
                }

                Button("Çıkış Yap", role: .destructive, action: onSignOut)
            }
            .navigationTitle("Profil")
            .sheet(isPresented: $isPhoneVerificationPresented) {
                NavigationStack {
                    PhoneEntryView {
                        isPhoneVerificationPresented = false
                        verificationMessage = "Telefon numaranız başarıyla doğrulandı."
                    }
                }
            }
            .sheet(isPresented: $isCallerIDInfoPresented) { callerIDInformation }
            .alert("Numara Doğrulama", isPresented: verificationAlertBinding) {
                Button("Tamam", role: .cancel) { verificationMessage = nil }
            } message: {
                Text(verificationMessage ?? "")
            }
        }
    }

    private var callerIDInformation: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "phone.badge.checkmark")
                    .font(.system(size: 54))
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                    .padding(.top, 22)
                Text("Arayan Kimliği Uzantısı")
                    .font(.title2.bold())
                Text("Bu özellik, iPhone’un arama ekranında WhoCall verileriyle eşleşen numaraların kimliğini göstermek için kullanılır. iOS güvenliği nedeniyle izin, cihaz ayarlarından kullanıcı tarafından açılır.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button("WhoCall Ayarlarını Aç") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
                .buttonStyle(PrimaryButtonStyle(background: DesignTokens.ColorToken.brandBlue))
                Spacer()
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { isCallerIDInfoPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func verifyPhoneNumber() {
        if let phoneNumber {
            verificationMessage = "\(formattedPhoneNumber(phoneNumber)) numarası Firebase SMS doğrulamasıyla onaylanmış durumda."
        } else {
            isPhoneVerificationPresented = true
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

    private func formattedPhoneNumber(_ number: String) -> String {
        let digits = number.filter(\.isNumber)
        guard digits.count >= 10 else { return number }
        let value = String(digits.suffix(10))
        return "+90 \(value.prefix(3)) \(value.dropFirst(3).prefix(3)) \(value.dropFirst(6).prefix(2)) \(value.suffix(2))"
    }

    private var verificationAlertBinding: Binding<Bool> {
        Binding(
            get: { verificationMessage != nil },
            set: { if !$0 { verificationMessage = nil } }
        )
    }
}
