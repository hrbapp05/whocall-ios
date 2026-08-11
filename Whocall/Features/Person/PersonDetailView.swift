import SwiftUI

struct PersonDetailView: View {
    let name: String
    let number: String
    let onComments: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text(String(name.prefix(1))).font(.title2.weight(.bold)).frame(width: 64, height: 64).background(DesignTokens.ColorToken.mint, in: .circle)
                Text(name).font(.headline)
                Text(number).font(.subheadline)

                HStack(spacing: 28) {
                    action("Ara", "phone")
                    action("Kaydet", "person.badge.plus")
                    action("Raporla", "exclamationmark.bubble")
                }

                VStack(spacing: 0) {
                    HStack { Text("Güven Seviyesi"); Spacer(); Text("Yüksek").foregroundStyle(DesignTokens.ColorToken.success); Image(systemName: "checkmark.shield.fill").foregroundStyle(DesignTokens.ColorToken.success) }
                    Divider().padding(.vertical, 12)
                    Button(action: onComments) { HStack { Label("Topluluk Yorumları", systemImage: "bubble.left"); Spacer(); Text("12") } }.buttonStyle(.plain)
                    Divider().padding(.vertical, 12)
                    HStack { Label("Etiketler", systemImage: "number"); Spacer(); Text("Komşu  Kankam  Tesisatçı").font(.caption).foregroundStyle(DesignTokens.ColorToken.brandBlue) }
                    Divider().padding(.vertical, 12)
                    Button(action: onComments) { HStack { Label("Yorum Ekle", systemImage: "square.and.pencil"); Spacer(); Image(systemName: "chevron.right") } }.buttonStyle(.plain)
                }
                .padding()
                .background(DesignTokens.ColorToken.card, in: .rect(cornerRadius: 18))

                HStack { Text("Topluluk Yorumları (12)").font(.headline); Spacer(); Button("Tümünü Gör", action: onComments) }
                ForEach(Comment.sample.prefix(3)) { CommentRow(comment: $0) }
            }
            .padding(20)
        }
        .navigationTitle("Kişi Kartı")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func action(_ title: String, _ symbol: String) -> some View {
        VStack { Image(systemName: symbol).frame(width: 44, height: 44).background(DesignTokens.ColorToken.card, in: .rect(cornerRadius: 12)); Text(title).font(.caption) }
    }
}

