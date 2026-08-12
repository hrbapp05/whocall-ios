import SwiftUI

struct CommentRow: View {
    let comment: Comment
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(comment.initial)
                .font(.system(size: 11, weight: .bold))
                .frame(width: 30, height: 30)
                .background(color, in: .circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(comment.author)
                    .font(.system(size: 14, weight: .semibold))
                Text("“\(comment.body)”")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(uiColor: .darkGray))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(comment.time)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: .rect(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black.opacity(0.045)))
        .shadow(color: .black.opacity(0.035), radius: 10, y: 5)
    }
}

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CommunityStore.self) private var communityStore
    let personName: String
    let phoneNumber: String
    @State private var isComposerPresented = false
    @State private var draftComment = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let avatarColors = [
        Color(red: 0.73, green: 0.74, blue: 0.96),
        Color(red: 0.91, green: 0.80, blue: 0.69),
        Color(red: 0.95, green: 0.83, blue: 0.87),
        Color(red: 0.71, green: 0.89, blue: 0.85),
        Color(red: 0.96, green: 0.86, blue: 0.56)
    ]

    init(personName: String, phoneNumber: String, startsComposing: Bool = false) {
        self.personName = personName
        self.phoneNumber = phoneNumber
        _isComposerPresented = State(initialValue: startsComposing)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 8) {
                    if comments.isEmpty {
                        ContentUnavailableView(
                            "Henüz yorum yok",
                            systemImage: "bubble.left.and.bubble.right",
                            description: Text("Bu numara hakkındaki ilk topluluk yorumunu siz ekleyebilirsiniz.")
                        )
                        .padding(.top, 64)
                    } else {
                        ForEach(Array(comments.enumerated()), id: \.element.id) { index, comment in
                            CommentRow(comment: comment, color: avatarColors[index % avatarColors.count])
                                .figmaEntrance(delay: min(Double(index) * 0.025, 0.18), distance: 10)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isComposerPresented) { composer }
        .task { await communityStore.refresh(for: phoneNumber) }
    }

    private var header: some View {
        HStack {
            FigmaBackButton { dismiss() }
            Spacer()
            Text("Topluluk Yorumları")
                .font(.system(size: 17, weight: .semibold))
            Spacer()
            Button { isComposerPresented = true } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.black)
                    .frame(width: 36, height: 36)
                    .background(.white, in: .circle)
                    .shadow(color: .black.opacity(0.07), radius: 18, y: 7)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Yorum ekle")
        }
        .padding(.horizontal, 20)
        .frame(height: 58)
    }

    private var composer: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text(personName)
                    .font(.headline)
                TextField("Yorumunuzu yazın", text: $draftComment, axis: .vertical)
                    .lineLimit(4...7)
                    .padding(14)
                    .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                Button("Yorumu Gönder") {
                    submitComment()
                }
                .buttonStyle(PrimaryButtonStyle(background: DesignTokens.ColorToken.brandBlue))
                .disabled(draftComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("Yorum Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { isComposerPresented = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var comments: [Comment] {
        communityStore.comments(for: phoneNumber)
    }

    private func submitComment() {
        let submittedComment = draftComment
        isSubmitting = true
        errorMessage = nil
        draftComment = ""
        isComposerPresented = false
        Task {
            do {
                try await communityStore.addComment(
                    submittedComment,
                    for: phoneNumber,
                    author: ProfileServiceFactory.live().currentDisplayName ?? "WhoCall Kullanıcısı"
                )
            } catch {
                errorMessage = error.localizedDescription
                draftComment = submittedComment
                isComposerPresented = true
            }
            isSubmitting = false
        }
    }
}
