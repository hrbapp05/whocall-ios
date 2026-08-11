import SwiftUI

struct PremiumView: View {
    @State private var selectedPlan = 1
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("PremiumHero").resizable().scaledToFit().frame(height: 230)
                Text("Daha Fazlasını Keşfet!").font(.title2.weight(.bold))
                Text("WhoCall Premium ile tüm bilgilerin kilidini açın.").foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 12) {
                    Label("Güven Seviyesini Görüntüle", systemImage: "checkmark")
                    Label("Tüm özelliklere sınırsız erişim", systemImage: "checkmark")
                    Label("Kişi adı ve etiketleri görüntüle", systemImage: "checkmark")
                }
                plan(0, "Haftalık Premium", "499,99 /hafta")
                plan(1, "Aylık Premium", "999,99 /ay")
                Button("Premium’a Geç") { }.buttonStyle(PrimaryButtonStyle())
                Text("Abonelik Koşulları  •  Gizlilik Politikası  •  Geri Yükle").font(.caption2).foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .navigationTitle("Premium ol")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func plan(_ index: Int, _ title: String, _ price: String) -> some View {
        Button { selectedPlan = index } label: {
            HStack { Image(systemName: selectedPlan == index ? "largecircle.fill.circle" : "circle"); VStack(alignment: .leading) { Text(title).font(.headline); Text(index == 0 ? "Haftalık Tam Erişim" : "Aylık Tam Erişim").font(.caption) }; Spacer(); Text(price).font(.subheadline.weight(.bold)) }
                .padding().background(DesignTokens.ColorToken.card, in: .rect(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}

