import SwiftUI

struct LegalConsentView: View {
    let onAccepted: @MainActor () async throws -> Void
    var onDeclined: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var acceptsTerms = false
    @State private var acknowledgesNotice = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.ColorToken.brandBlue.opacity(0.1))
                            .frame(width: 112, height: 112)
                        Circle()
                            .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.22), lineWidth: 1)
                            .frame(width: 86, height: 86)
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 38, weight: .semibold))
                            .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                    }
                    .padding(.top, 8)
                    .popEntrance(delay: 0.06, initialScale: 0.75)

                    VStack(spacing: 8) {
                        Text("Devam Etmeden Önce")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.8)
                        Text("Telefon numaranızı SMS ile doğrulamak ve WhoCall hesabınızı oluşturmak için aşağıdaki metinleri ayrı ayrı inceleyin.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(spacing: 12) {
                        consentRow(
                            isSelected: $acceptsTerms,
                            prefix: "Kullanım Koşulları’nı",
                            suffix: " okudum ve kabul ediyorum.",
                            document: .termsOfUse,
                            accessibilityID: "legal.terms"
                        )
                        consentRow(
                            isSelected: $acknowledgesNotice,
                            prefix: "KVKK Aydınlatma Metni",
                            suffix: " tarafıma sunuldu; okudum ve bilgi edindim.",
                            document: .kvkkNotice,
                            accessibilityID: "legal.kvkk"
                        )
                    }

                    NavigationLink(value: LegalDocument.privacyPolicy) {
                        Label("Gizlilik Politikası’nı İncele", systemImage: "lock.doc")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        Task { await accept() }
                    } label: {
                        Group {
                            if isSaving {
                                ProgressView().tint(.white)
                            } else {
                                Text("Kabul Et ve Devam Et")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!canContinue || isSaving)
                    .opacity(canContinue ? 1 : 0.42)
                    .accessibilityIdentifier("legal.continue")

                    Button("Şimdilik Değil") {
                        if let onDeclined {
                            onDeclined()
                        } else {
                            dismiss()
                        }
                    }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .disabled(isSaving)
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
            .background(DesignTokens.ColorToken.background)
            .navigationDestination(for: LegalDocument.self) { document in
                LegalDocumentView(document: document)
            }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private var canContinue: Bool {
        acceptsTerms && acknowledgesNotice
    }

    private func consentRow(
        isSelected: Binding<Bool>,
        prefix: String,
        suffix: String,
        document: LegalDocument,
        accessibilityID: String
    ) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Button {
                withAnimation(.spring(response: 0.34, dampingFraction: 0.75)) {
                    isSelected.wrappedValue.toggle()
                }
            } label: {
                Image(systemName: isSelected.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 25, weight: .medium))
                    .foregroundStyle(isSelected.wrappedValue ? DesignTokens.ColorToken.brandBlue : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(accessibilityID)

            (Text(prefix).foregroundStyle(DesignTokens.ColorToken.brandBlue).underline() + Text(suffix))
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
                .overlay {
                    NavigationLink(value: document) { Color.clear }
                        .accessibilityLabel("\(prefix) metnini aç")
                }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(isSelected.wrappedValue ? DesignTokens.ColorToken.brandBlue.opacity(0.42) : Color.black.opacity(0.06))
        }
    }

    @MainActor
    private func accept() async {
        guard canContinue, !isSaving else { return }
        isSaving = true
        errorMessage = nil
        do {
            try await onAccepted()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

struct LegalConsentGateView: View {
    let onAccepted: @MainActor () async throws -> Void
    let onDeclined: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [DesignTokens.ColorToken.brandBlue.opacity(0.08), DesignTokens.ColorToken.background],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            LegalConsentView(onAccepted: onAccepted, onDeclined: onDeclined)
                .clipShape(.rect(cornerRadius: 32))
                .padding(.horizontal, 10)
                .padding(.vertical, 18)
        }
    }
}
