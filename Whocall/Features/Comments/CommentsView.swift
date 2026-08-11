import SwiftUI

struct Comment: Identifiable, Sendable {
    let id = UUID()
    let initial: String
    let author: String
    let body: String
    let time: String

    static let sample = [
        Comment(initial: "M", author: "Mehmet K.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "A", author: "Ahmet S.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "E", author: "Elif Y.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün"),
        Comment(initial: "F", author: "Fatma G.", body: "Kendisini çok yakından tanırız.", time: "Dün"),
        Comment(initial: "B", author: "Burak T.", body: "Mahallemizde oturuyor, güvenilir bir kişi", time: "Dün")
    ]
}

struct CommentRow: View {
    let comment: Comment
    var body: some View {
        HStack(alignment: .top) {
            Text(comment.initial).font(.caption.weight(.bold)).frame(width: 40, height: 40).background(DesignTokens.ColorToken.mint, in: .circle)
            VStack(alignment: .leading, spacing: 5) { Text(comment.author).font(.headline); Text("“\(comment.body)”").font(.subheadline).foregroundStyle(.secondary) }
            Spacer()
            Text(comment.time).font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct CommentsView: View {
    @State private var comment = ""
    var body: some View {
        List {
            ForEach(Comment.sample) { CommentRow(comment: $0) }
            Section("Yorum Bırak") {
                TextField("Yorumunuzu yazın", text: $comment, axis: .vertical)
                Button("Gönder") { comment = "" }.disabled(comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .listStyle(.plain)
        .navigationTitle("Topluluk Yorumları")
        .navigationBarTitleDisplayMode(.inline)
    }
}
