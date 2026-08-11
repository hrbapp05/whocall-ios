import SwiftUI

struct ProfileView: View {
    let onSignOut: () -> Void
    @State private var isVisible = true

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Text("G").font(.title2.weight(.bold)).frame(width: 64, height: 64).background(DesignTokens.ColorToken.mint, in: .circle)
                        VStack(alignment: .leading) { Text("Göktuğ S.").font(.headline); Text("+90 506 158 55 98").foregroundStyle(.secondary); Text("40 Etiket").font(.caption).foregroundStyle(DesignTokens.ColorToken.brandBlue) }
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
}

