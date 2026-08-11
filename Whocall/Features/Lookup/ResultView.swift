import SwiftUI

struct ResultView: View {
    let owner: PhoneOwner
    let onDetails: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text(owner.phoneNumber).font(.title2.weight(.bold))
            Text("Sorgulama Tamamlandı").foregroundStyle(.secondary)

            VStack(spacing: 12) {
                HStack {
                    Text(String(owner.displayName.prefix(1))).font(.headline).frame(width: 50, height: 50).background(DesignTokens.ColorToken.mint, in: .circle)
                    VStack(alignment: .leading) {
                        Text("\(owner.displayName) Olarak Biliniyor").font(.headline)
                        Text("Muhtemel Kişi").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }
                Divider()
                HStack { Label("Topluluk Yorumları", systemImage: "bubble.left"); Spacer(); Text("12") }
                Divider()
                HStack { Label("Etiketler", systemImage: "number"); Spacer(); Text("Komşu  Kankam  Tesisatçı").font(.caption).foregroundStyle(DesignTokens.ColorToken.brandBlue) }
            }
            .padding()
            .background(DesignTokens.ColorToken.card, in: .rect(cornerRadius: 18))

            Spacer()
            Button("Detayları Gör", action: onDetails).buttonStyle(PrimaryButtonStyle())
        }
        .padding(20)
        .navigationTitle("Sonuç Bulundu")
        .navigationBarTitleDisplayMode(.inline)
    }
}

