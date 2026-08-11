import SwiftUI

struct PersonDetailView: View {
    let name: String
    let number: String
    let onComments: () -> Void

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
        .toolbar { ToolbarItem(placement: .topBarTrailing) { ToolbarCreditBadge() } }
    }

    private var personHeader: some View {
        VStack(spacing: 7) {
            Text(String(name.prefix(1)).uppercased())
                .font(.title2.weight(.bold))
                .frame(width: 78, height: 78)
                .background(DesignTokens.ColorToken.mint, in: .circle)
                .offset(y: -34)
                .padding(.bottom, -34)
                .figmaEntrance(delay: 0.04, distance: 20)

            Text("\(name) Olarak Biliniyor")
                .font(.headline)
            Text(displayNumber)
                .font(.body)

            HStack(spacing: 16) {
                action("Ara", "phone", tint: .primary)
                action("Kaydet", "person.badge.plus", tint: .primary)
                action("Raporla", "exclamationmark.shield", tint: .red)
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

    private func action(_ title: String, _ symbol: String, tint: Color) -> some View {
        Button { } label: {
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
                HStack { Label("Topluluk Yorumları", systemImage: "bubble.left"); Spacer(); Text("12") }
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            Divider()
            HStack(spacing: 8) {
                Label("Etiketler", systemImage: "number")
                Spacer(minLength: 2)
                FigmaTag(title: "Komşu")
                FigmaTag(title: "Kankam")
                FigmaTag(title: "Tesisatçı")
            }
            .frame(height: 48)
            Divider()
            Button(action: onComments) {
                HStack { Label("Yorum Ekle", systemImage: "square.and.pencil"); Spacer(); Image(systemName: "chevron.right") }
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

    private var commentsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Topluluk Yorumları (12)").font(.headline)
                Spacer()
                Button("Tümünü Gör", action: onComments)
            }
            ForEach(Array(Comment.sample.prefix(3).enumerated()), id: \.element.id) { index, comment in
                personComment(comment, color: commentColors[index])
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
}
