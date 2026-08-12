import SwiftUI

struct PersonDetailView: View {
    @Environment(CommunityStore.self) private var communityStore
    @Environment(\.openURL) private var openURL
    let name: String
    let number: String
    let onComments: () -> Void
    let onAddComment: () -> Void
    let onCredits: () -> Void
    @State private var isReportPresented = false
    @State private var isTagsPresented = false
    @State private var newContactDraft: NewContactDraft?
    @State private var alertMessage: String?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                personHeader
                informationCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .figmaEntrance(delay: 0.12, distance: 14)
                commentsSection
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                    .figmaEntrance(delay: 0.2, distance: 16)
            }
            .background(
                Color(.systemBackground),
                in: .rect(topLeadingRadius: 42, topTrailingRadius: 42)
            )
            .padding(.top, 34)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Kişi Kartı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onCredits) { ToolbarCreditBadge() }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Kredi yükle")
            }
        }
        .confirmationDialog("Bu numarayı raporla", isPresented: $isReportPresented, titleVisibility: .visible) {
            ForEach(reportReasons, id: \.self) { reason in
                Button(reason) {
                    Task {
                        do {
                            try await communityStore.report(phoneNumber: number, reason: reason)
                            alertMessage = "Raporunuz alındı. Teşekkür ederiz."
                        } catch {
                            alertMessage = "Rapor gönderilemedi. Lütfen tekrar deneyin."
                        }
                    }
                }
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Topluluğu korumamıza yardımcı olmak için bir neden seçin.")
        }
        .alert("WhoCall", isPresented: alertBinding) {
            Button("Tamam", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $isTagsPresented) {
            TagsView(phoneNumber: number)
        }
        .sheet(item: $newContactDraft) { draft in
            NewContactComposer(draft: draft) {
                newContactDraft = nil
            }
        }
        .task { await communityStore.refresh(for: number) }
    }

    private var personHeader: some View {
        VStack(spacing: 7) {
            Text(String(safeName.prefix(1)).uppercased())
                .font(.title2.weight(.bold))
                .frame(width: 78, height: 78)
                .background(DesignTokens.ColorToken.mint, in: .circle)
                .offset(y: -34)
                .padding(.bottom, -34)
                .figmaEntrance(delay: 0.04, distance: 20)

            Text("\(safeName) Olarak Biliniyor")
                .font(.headline)
            Text(displayNumber)
                .font(.body)

            HStack(spacing: 16) {
                action("Ara", "phone", tint: .primary, perform: call)
                action("Kaydet", "person.badge.plus", tint: .primary, perform: saveContact)
                action("Raporla", "exclamationmark.shield", tint: .red) { isReportPresented = true }
            }
            .padding(.top, 10)
        }
        .frame(maxWidth: .infinity)
    }

    private var displayNumber: String {
        let digits = number.filter(\.isNumber)
        guard digits.count >= 10 else { return number }
        let value = String(digits.suffix(10))
        return "+90 \(value.prefix(3)) \(value.dropFirst(3).prefix(3)) \(value.dropFirst(6).prefix(2)) \(value.suffix(2))"
    }

    private func action(_ title: String, _ symbol: String, tint: Color, perform: @escaping () -> Void) -> some View {
        Button(action: perform) {
            VStack(spacing: 8) {
                Image(systemName: symbol).font(.title2).foregroundStyle(tint)
                Text(title).font(.caption).foregroundStyle(.primary)
            }
            .frame(width: 70, height: 70)
            .background(.white, in: .rect(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.separator).opacity(0.45)))
            .shadow(color: .black.opacity(0.04), radius: 9, y: 5)
        }
        .buttonStyle(.plain)
    }

    private var informationCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Güven Seviyesi")
                Spacer()
                Text("Yüksek").foregroundStyle(DesignTokens.ColorToken.success)
                Image(systemName: "checkmark.shield.fill").foregroundStyle(DesignTokens.ColorToken.success)
            }
            .frame(height: 44)
            Divider()
            Button(action: onComments) {
                HStack {
                    Label("Topluluk Yorumları", systemImage: "bubble.left")
                    Spacer()
                    Text("\(comments.count)")
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)
            Divider()
            Button { isTagsPresented = true } label: { labelsRow }
                .buttonStyle(.plain)
            Divider()
            Button(action: onAddComment) {
                HStack {
                    Label("Yorum Ekle", systemImage: "square.and.pencil")
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .frame(height: 44)
            }
            .buttonStyle(.plain)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .background(.white, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.separator).opacity(0.32)))
        .shadow(color: .black.opacity(0.035), radius: 12, y: 5)
    }

    private var labelsRow: some View {
        HStack(spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "number")
                Text("Etiketler")
            }
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(2)
            Spacer(minLength: 0)
            if tags.isEmpty {
                Text("Etiket ekle")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            } else {
                ForEach(Array(tags.prefix(2)), id: \.self) { compactTag($0) }
                if tags.count > 2 { compactTag("+\(tags.count - 2)") }
            }
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(height: 48)
    }

    private func compactTag(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10))
            .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            .padding(.horizontal, 7)
            .frame(height: 24)
            .background(DesignTokens.ColorToken.brandBlue.opacity(0.11), in: .capsule)
            .fixedSize(horizontal: true, vertical: false)
    }

    private var commentsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Topluluk Yorumları (\(comments.count))").font(.headline)
                Spacer()
                Button("Tümünü Gör", action: onComments)
            }
            if comments.isEmpty {
                VStack(spacing: 7) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                    Text("Henüz topluluk yorumu yok")
                        .font(.subheadline.weight(.semibold))
                    Button("İlk yorumu ekle", action: onAddComment)
                        .font(.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            } else {
                ForEach(Array(comments.prefix(3).enumerated()), id: \.element.id) { index, comment in
                    personComment(comment, color: commentColors[index])
                }
            }
        }
        .padding(16)
        .background(Color(red: 0.95, green: 0.95, blue: 0.96), in: .rect(cornerRadius: 20))
    }

    private let commentColors: [Color] = [
        Color(red: 0.72, green: 0.72, blue: 0.97),
        Color(red: 0.91, green: 0.79, blue: 0.69),
        Color(red: 0.95, green: 0.82, blue: 0.86)
    ]

    private func personComment(_ comment: Comment, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(comment.initial)
                .font(.caption.weight(.bold))
                .frame(width: 36, height: 36)
                .background(color, in: .circle)
            VStack(alignment: .leading, spacing: 4) {
                Text(comment.author).font(.subheadline.weight(.bold))
                Text("“\(comment.body)”").font(.caption).lineLimit(2)
            }
            Spacer()
            Text(comment.time).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.white, in: .rect(cornerRadius: 18))
    }

    private var safeName: String { PersonNameFormatter.maskFullName(name) }
    private var comments: [Comment] { communityStore.comments(for: number) }
    private var tags: [String] { communityStore.tags(for: number) }

    private let reportReasons = [
        "Spam veya dolandırıcılık",
        "Taciz veya istenmeyen arama",
        "Yanlış kişi bilgisi",
        "Diğer"
    ]

    private func call() {
        let digits = number.filter(\.isNumber)
        guard let url = URL(string: "tel://\(digits)") else { return }
        openURL(url) { accepted in
            if !accepted { alertMessage = "Bu cihaz telefon araması başlatamıyor." }
        }
    }

    private func saveContact() {
        guard number.filter(\.isNumber).count >= 10 else {
            alertMessage = "Telefon numarası geçerli değil."
            return
        }
        newContactDraft = NewContactDraft(name: safeName, phoneNumber: displayNumber)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }
}

private struct TagsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(CommunityStore.self) private var communityStore
    let phoneNumber: String
    @State private var draft = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                Text("Bu numara için topluluğun eklediği tüm etiketler")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if tags.isEmpty {
                    ContentUnavailableView(
                        "Henüz etiket yok",
                        systemImage: "number",
                        description: Text("Bu numarayı tanımlayan ilk etiketi siz ekleyebilirsiniz.")
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.self) { FigmaTag(title: $0) }
                    }
                }

                Divider()

                HStack(spacing: 10) {
                    TextField("Örn. Tesisatçı", text: $draft)
                        .textInputAutocapitalization(.words)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                    Button("Ekle") { addTag() }
                        .font(.subheadline.weight(.semibold))
                        .disabled(!canSubmit || isSubmitting)
                }

                if let errorMessage {
                    Text(errorMessage).font(.caption).foregroundStyle(.red)
                }
                Spacer()
            }
            .padding(20)
            .navigationTitle("Etiketler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bitti") { dismiss() }
                }
            }
            .task { await communityStore.refresh(for: phoneNumber) }
        }
        .presentationDetents([.medium, .large])
    }

    private var tags: [String] { communityStore.tags(for: phoneNumber) }
    private var canSubmit: Bool {
        let count = draft.trimmingCharacters(in: .whitespacesAndNewlines).count
        return (2...24).contains(count)
    }

    private func addTag() {
        isSubmitting = true
        errorMessage = nil
        Task {
            do {
                try await communityStore.addTag(draft, for: phoneNumber)
                draft = ""
            } catch {
                errorMessage = "Etiket eklenemedi. Lütfen tekrar deneyin."
            }
            isSubmitting = false
        }
    }
}

private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, point) in result.points.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + point.x, y: bounds.minY + point.y), proposal: .unspecified)
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, points: [CGPoint]) {
        let width = proposal.width ?? 320
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var points: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            points.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: width, height: y + rowHeight), points)
    }
}
