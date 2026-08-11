import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selected = 5

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                creditHero
                    .padding(.top, 16)
                    .figmaEntrance(delay: 0.04, distance: 14)

                Text("Sorgular için")
                    .font(.body)
                    .padding(.top, 6)
                HStack(spacing: 4) {
                    Text("Kredi")
                    Text("Satın Al").foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }
                .font(.title2.weight(.bold))
                .padding(.top, 4)
                Text("Abonelik gerektirmeden sorguların için kredi alabilirsin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)

                VStack(spacing: 16) {
                    creditOption(3, price: "199,99")
                    creditOption(5, price: "249,99")
                    creditOption(10, price: "499,99")
                }
                .padding(.horizontal, 32)
                .padding(.top, 32)
            }
            .padding(.bottom, 92)
        }
        .background(Color(red: 0.97, green: 0.98, blue: 1).ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: { Image(systemName: "xmark") }
                    .tint(.primary)
            }
            ToolbarItem(placement: .principal) {
                Image("WhoCallLogo").resizable().scaledToFit().frame(width: 98, height: 20)
            }
            ToolbarItem(placement: .topBarTrailing) { ToolbarCreditBadge() }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button("Kredi Satın Al") { }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .background(.ultraThinMaterial)
        }
    }

    private var creditHero: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.ColorToken.brandBlue.opacity(0.045))
                .overlay(Circle().stroke(DesignTokens.ColorToken.brandBlue.opacity(0.2), lineWidth: 1))
                .frame(width: 210, height: 210)
            Image("CreditHero")
                .resizable().scaledToFit().frame(width: 210, height: 210)
                .gentleFloat(distance: 6, duration: 2.6)
        }
        .frame(height: 230)
    }

    private func creditOption(_ amount: Int, price: String) -> some View {
        Button {
            withAnimation(.spring(duration: 0.35, bounce: 0.18)) { selected = amount }
        } label: {
            HStack(spacing: 8) {
                Image("CreditGlyph").resizable().scaledToFit().frame(width: 26, height: 26)
                Text("\(amount)").font(.title.weight(.bold))
                Spacer()
                Text(price).font(.subheadline.weight(.semibold))
                Image(systemName: selected == amount ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .padding(.horizontal, 16)
            .frame(height: 74)
            .background(.white, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(selected == amount ? DesignTokens.ColorToken.brandBlue : .clear, lineWidth: 2)
            }
            .overlay(alignment: .top) {
                if amount == 5 {
                    Text("En Popüler")
                        .font(.caption2.weight(.semibold)).foregroundStyle(.white)
                        .padding(.horizontal, 10).padding(.vertical, 3)
                        .background(DesignTokens.ColorToken.brandBlue, in: .capsule)
                        .offset(y: -10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
