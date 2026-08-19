import SwiftUI

enum CommunitySafetyAction: Identifiable {
    case reportComment(comment: Comment, phoneNumber: String)
    case blockCommentAuthor(comment: Comment, phoneNumber: String)
    case reportTag(tag: String, phoneNumber: String)

    var id: String {
        switch self {
        case let .reportComment(comment, phoneNumber):
            "report-comment:\(phoneNumber):\(comment.id)"
        case let .blockCommentAuthor(comment, phoneNumber):
            "block-author:\(phoneNumber):\(comment.id)"
        case let .reportTag(tag, phoneNumber):
            "report-tag:\(phoneNumber):\(tag)"
        }
    }

    fileprivate var title: String {
        switch self {
        case .reportComment:
            "Yorumu Şikâyet Et"
        case .blockCommentAuthor:
            "Kullanıcıyı Engelle"
        case .reportTag:
            "Etiketi Şikâyet Et"
        }
    }

    fileprivate var explanation: String {
        switch self {
        case .reportComment, .reportTag:
            "İçerik hemen sizin ekranınızdan kaldırılır ve moderasyon ekibimize gönderilir. Bildirimler en geç 24 saat içinde incelenir."
        case .blockCommentAuthor:
            "Bu kullanıcının tüm yorumları hemen gizlenir. Engelleme işlemi aynı zamanda moderasyon ekibimize kötüye kullanım bildirimi gönderir."
        }
    }

    fileprivate var symbol: String {
        switch self {
        case .reportComment, .reportTag:
            "flag.fill"
        case .blockCommentAuthor:
            "person.crop.circle.badge.xmark"
        }
    }

    fileprivate var buttonTitle: String {
        switch self {
        case .reportComment, .reportTag:
            "Şikâyeti Gönder"
        case .blockCommentAuthor:
            "Engelle ve Bildir"
        }
    }
}

struct CommunitySafetySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CommunityStore.self) private var communityStore

    let action: CommunitySafetyAction

    @State private var selectedReason = CommunityModerationReason.abusiveLanguage
    @State private var isSubmitting = false
    @State private var isComplete = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isComplete {
                    completionContent
                } else {
                    formContent
                }
            }
            .background(DesignTokens.ColorToken.background.ignoresSafeArea())
            .navigationTitle(action.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isComplete {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Vazgeç") { dismiss() }
                            .disabled(isSubmitting)
                    }
                }
            }
        }
        .interactiveDismissDisabled(isSubmitting)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: action.symbol)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 68, height: 68)
                    .background(Color.red, in: .circle)
                    .popEntrance(delay: 0.04, initialScale: 0.72)

                Text(action.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Neden")
                        .font(.headline)

                    ForEach(CommunityModerationReason.allCases) { reason in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                selectedReason = reason
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedReason == reason ?
                                      "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 21, weight: .medium))
                                    .foregroundStyle(selectedReason == reason ?
                                                     DesignTokens.ColorToken.brandBlue : .secondary)
                                Text(reason.rawValue)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                    .multilineTextAlignment(.leading)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 15)
                            .frame(minHeight: 50)
                            .background(.white, in: .rect(cornerRadius: 15))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(selectedReason == reason ?
                                            DesignTokens.ColorToken.brandBlue.opacity(0.4) :
                                            Color.black.opacity(0.05))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await submit() }
                } label: {
                    Group {
                        if isSubmitting {
                            ProgressView().tint(.white)
                        } else {
                            Text(action.buttonTitle)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle(background: Color.red))
                .disabled(isSubmitting)
                .accessibilityIdentifier("community.safety.submit")
            }
            .padding(20)
        }
    }

    private var completionContent: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(DesignTokens.ColorToken.success)
                .popEntrance(delay: 0.02, initialScale: 0.55)
            Text("İşleminiz Alındı")
                .font(.title2.bold())
            Text("İçerik ekranınızdan kaldırıldı. Moderasyon ekibimiz bildirimi 24 saat içinde inceleyecek.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("Tamam") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
        }
        .padding(28)
    }

    @MainActor
    private func submit() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        errorMessage = nil
        do {
            switch action {
            case let .reportComment(comment, phoneNumber):
                try await communityStore.report(
                    comment: comment,
                    phoneNumber: phoneNumber,
                    reason: selectedReason
                )
            case let .blockCommentAuthor(comment, phoneNumber):
                try await communityStore.block(
                    authorOf: comment,
                    phoneNumber: phoneNumber,
                    reason: selectedReason
                )
            case let .reportTag(tag, phoneNumber):
                try await communityStore.report(
                    tag: tag,
                    phoneNumber: phoneNumber,
                    reason: selectedReason
                )
            }
            withAnimation(.easeInOut(duration: 0.22)) {
                isComplete = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isSubmitting = false
    }
}
