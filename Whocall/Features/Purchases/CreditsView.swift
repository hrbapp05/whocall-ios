import SwiftUI

struct CreditsView: View {
    @State private var selected = 10
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image("CreditHero").resizable().scaledToFit().frame(height: 250)
                Text("Sorgular için Kredi Satın Al").font(.title2.weight(.bold))
                Text("Abonelik gerektirmeden sorguların için kredi alabilirsin.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                ForEach([(3, "199,99"), (5, "249,99"), (10, "499,99")], id: \.0) { option in
                    Button { selected = option.0 } label: {
                        HStack { Image(systemName: selected == option.0 ? "largecircle.fill.circle" : "circle"); Text("\(option.0) Kredi").font(.headline); Spacer(); Text(option.1).font(.headline) }.padding().background(DesignTokens.ColorToken.card, in: .rect(cornerRadius: 16))
                    }.buttonStyle(.plain)
                }
                Button("Kredi Satın Al") { }.buttonStyle(PrimaryButtonStyle())
            }.padding(20)
        }
        .navigationTitle("Kredi Al")
        .navigationBarTitleDisplayMode(.inline)
    }
}

