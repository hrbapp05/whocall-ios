import SwiftUI

struct ProfileView: View {
    let onSignOut: () -> Void
    @Environment(PurchaseStore.self) private var purchaseStore
    @Environment(RecentLookupStore.self) private var recentLookupStore
    @State private var isVisible = true
    @State private var visibilityState = VerifiedProfileVisibilityState.visible
    @State private var isUpdatingVisibility = false
    @State private var visibilityDialog: VisibilityDialog?
    @State private var isPhoneVerificationPresented = false
    @State private var verificationMessage: String?
    @State private var isDeleteConfirmationPresented = false
    @State private var isDeletingAccount = false

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

                Section {
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

                    Toggle("Arama sonuçlarında görünürlük", isOn: visibilityBinding)
                        .disabled(isUpdatingVisibility)
                } header: {
                    Text("Hesabım")
                } footer: {
                    if !isVisible {
                        Text(visibilityFooterMessage)
                    }
                }

                Section("Satın Alımlar") {
                    NavigationLink { SubscriptionHistoryView() } label: {
                        Label("Aboneliklerim", systemImage: "crown")
                    }
                    NavigationLink { CreditPurchaseHistoryView() } label: {
                        Label("Kredi Alımlarım", systemImage: "creditcard")
                    }
                }

                Section("Bildirimler") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        Label("Bildirim Ayarları", systemImage: "bell.badge")
                    }
                }

                Section("Destek") {
                    Link(destination: URL(string: "mailto:support@levelappstudio.com")!) {
                        Label("Bize Ulaşın", systemImage: "envelope")
                    }
                    NavigationLink {
                        LegalDocumentView(document: .privacyPolicy)
                    } label: {
                        Label("Gizlilik Politikası", systemImage: "lock.shield")
                    }
                    NavigationLink {
                        LegalDocumentView(document: .kvkkNotice)
                    } label: {
                        Label("KVKK Aydınlatma Metni", systemImage: "person.text.rectangle")
                    }
                    NavigationLink {
                        LegalDocumentView(document: .termsOfUse)
                    } label: {
                        Label("Kullanım Koşulları", systemImage: "doc.text")
                    }
                }

                Section("Hesap Yönetimi") {
                    Button(role: .destructive) {
                        isDeleteConfirmationPresented = true
                    } label: {
                        HStack {
                            Label("Hesabımı Sil", systemImage: "trash")
                            Spacer()
                            if isDeletingAccount { ProgressView() }
                        }
                    }
                    .disabled(isDeletingAccount)
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
            .alert("WhoCall", isPresented: verificationAlertBinding) {
                Button("Tamam", role: .cancel) { verificationMessage = nil }
            } message: {
                Text(verificationMessage ?? "")
            }
            .alert(item: $visibilityDialog) { dialog in
                switch dialog {
                case .confirmRepeatHide:
                    Alert(
                        title: Text("Görünürlüğü kapatmak istiyor musunuz?"),
                        message: Text("Görünürlüğü kapatırsanız 12 saat boyunca tekrar açamaz ve bu süre içinde başka kullanıcıları sorgulayamazsınız."),
                        primaryButton: .destructive(Text("Görünürlüğü Kapat")) {
                            updateVisibility(false, confirmsCooldown: true)
                        },
                        secondaryButton: .cancel(Text("Vazgeç"))
                    )
                case let .locked(canEnableAt):
                    Alert(
                        title: Text("Görünürlük geçici olarak kilitli"),
                        message: Text("Görünürlüğünüzü \(formattedLockDate(canEnableAt)) tarihinde yeniden açabilirsiniz. Bu süre içinde numara sorgulayamazsınız."),
                        dismissButton: .default(Text("Tamam"))
                    )
                case let .error(message):
                    Alert(
                        title: Text("WhoCall"),
                        message: Text(message),
                        dismissButton: .default(Text("Tamam"))
                    )
                }
            }
            .confirmationDialog(
                "WhoCall hesabınız kalıcı olarak silinsin mi?",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Hesabımı Kalıcı Olarak Sil", role: .destructive) {
                    Task { await deleteAccount() }
                }
                Button("Vazgeç", role: .cancel) {}
            } message: {
                Text("Doğrulanmış profiliniz, yasal tercih kaydınız, yorumlarınız ve raporlarınız silinir. Kimlikle ilişkilendirilmeyen topluluk istatistikleri ile Apple satın alma kayıtları ilgili saklama kurallarına tabi olabilir.")
            }
            .task {
                await loadVisibility()
            }
        }
    }

    private func verifyPhoneNumber() {
        if let phoneNumber {
            verificationMessage = "\(formattedPhoneNumber(phoneNumber)) numarası SMS doğrulamasıyla onaylanmış durumda."
        } else {
            isPhoneVerificationPresented = true
        }
    }

    private var visibilityBinding: Binding<Bool> {
        Binding(
            get: { isVisible },
            set: { requestedValue in
                guard requestedValue != isVisible, !isUpdatingVisibility else { return }
                if requestedValue {
                    if visibilityState.isEnableLocked, let canEnableAt = visibilityState.canEnableAt {
                        visibilityDialog = .locked(canEnableAt)
                    } else {
                        updateVisibility(true, confirmsCooldown: false)
                    }
                } else if visibilityState.requiresHideConfirmation {
                    visibilityDialog = .confirmRepeatHide
                } else {
                    updateVisibility(false, confirmsCooldown: false)
                }
            }
        )
    }

    @MainActor
    private func loadVisibility() async {
        let profile = ProfileServiceFactory.live()
        if let state = await ProfileVisibilitySynchronizer.synchronize() {
            visibilityState = state
            isVisible = state.isVisible
        } else {
            let localValue = ProfileVisibilityPreference.isVisible(userID: profile.currentUserID)
            isVisible = localValue
            visibilityState = .init(
                isVisible: localValue,
                hideCount: localValue ? 0 : 1,
                canEnableAt: nil
            )
        }
    }

    private func updateVisibility(_ newValue: Bool, confirmsCooldown: Bool) {
        let previousValue = isVisible
        withAnimation(.easeInOut(duration: 0.2)) { isVisible = newValue }
        isUpdatingVisibility = true
        Task {
            do {
                let state = try await VerifiedNumberDirectoryFactory.live().setOwnProfileVisibility(
                    newValue,
                    confirmsCooldown: confirmsCooldown
                )
                let profile = ProfileServiceFactory.live()
                visibilityState = state
                isVisible = state.isVisible
                ProfileVisibilityPreference.setVisible(state.isVisible, userID: profile.currentUserID)
            } catch {
                withAnimation(.easeInOut(duration: 0.2)) { isVisible = previousValue }
                visibilityDialog = .error(error.localizedDescription)
            }
            isUpdatingVisibility = false
        }
    }

    private var visibilityFooterMessage: String {
        if visibilityState.isEnableLocked, let canEnableAt = visibilityState.canEnableAt {
            return "Görünürlüğünüz \(formattedLockDate(canEnableAt)) tarihine kadar kapalıdır. Bu sürede numara sorgulayamazsınız."
        }
        return "Görünürlüğünüz kapalıyken arama sonuçlarında görünmez ve başka numaraları sorgulayamazsınız."
    }

    private func formattedLockDate(_ date: Date) -> String {
        date.formatted(
            Date.FormatStyle(date: .abbreviated, time: .shortened)
                .locale(Locale(identifier: "tr_TR"))
        )
    }

    @MainActor
    private func deleteAccount() async {
        guard !isDeletingAccount,
              let userID = ProfileServiceFactory.live().currentUserID else {
            verificationMessage = "Silinecek doğrulanmış hesap bulunamadı."
            return
        }

        isDeletingAccount = true
        defer { isDeletingAccount = false }

        do {
            try await LegalAccountServiceFactory.live().deleteCurrentAccount()
            recentLookupStore.clear()
            await purchaseStore.clearLocalAccountData(accountID: userID)
            ProfileVisibilityPreference.clear(userID: userID)
            NotificationPreference.clear(userID: userID)
            PendingVerifiedProfileStore.clear()
            LegalAcceptancePreference.clear(userID: userID)
            onSignOut()
        } catch {
            verificationMessage = error.localizedDescription
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

private enum VisibilityDialog: Identifiable {
    case confirmRepeatHide
    case locked(Date)
    case error(String)

    var id: String {
        switch self {
        case .confirmRepeatHide: "confirm-repeat-hide"
        case .locked: "locked"
        case .error: "error"
        }
    }
}
