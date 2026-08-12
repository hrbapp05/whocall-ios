import SwiftUI

struct ResultView: View {
    let owner: PhoneOwner
    let onDetails: () -> Void
    let onNewLookup: () -> Void
    let onCredits: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image("TurkeyFlag").resizable().frame(width: 18, height: 18)
                Text(displayNumber).font(.system(size: 32, weight: .semibold))
            }
            .padding(.top, 24)
            Label("Sorgulama Tamamlandı", systemImage: "checkmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                .padding(.top, 6)

            resultCard
                .padding(.horizontal, 20)
                .padding(.top, 34)
                .figmaEntrance(delay: 0.06, distance: 18)

            Button("Detayları Gör", action: onDetails)
                .buttonStyle(PrimaryButtonStyle(background: Color(red: 0.04, green: 0.04, blue: 0.06)))
                .padding(.horizontal, 20)
                .padding(.top, 18)

            Button("Yeni Sorgu Yap", action: onNewLookup)
                .buttonStyle(PrimaryButtonStyle(background: DesignTokens.ColorToken.brandBlue))
                .padding(.horizontal, 20)
                .padding(.top, 14)
            Spacer()
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Sonuç Bulundu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onCredits) { ToolbarCreditBadge() }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Kredi yükle")
            }
        }
    }

    private var displayNumber: String {
        let digits = owner.phoneNumber.filter(\.isNumber)
        guard digits.count >= 10 else { return owner.phoneNumber }
        let value = String(digits.suffix(10))
        return "\(value.prefix(3)) \(value.dropFirst(3).prefix(3)) \(value.dropFirst(6).prefix(2)) \(value.suffix(2))"
    }

    private var resultCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text(String(safeName.prefix(1)).uppercased())
                    .font(.subheadline.weight(.bold))
                    .frame(width: 50, height: 50)
                    .background(DesignTokens.ColorToken.mint, in: .circle)
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(safeName) Olarak Biliniyor").font(.subheadline.weight(.bold))
                    Text("Muhtemel Kişi").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "checkmark.seal.fill").foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .padding(.vertical, 12)
            Divider()
            HStack { Label("Topluluk Yorumları", systemImage: "bubble.left"); Spacer(); Text("12") }
                .frame(height: 44)
            Divider()
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "number")
                    Text("Etiketler")
                }
                .fixedSize(horizontal: true, vertical: false)
                .layoutPriority(2)
                Spacer(minLength: 0)
                compactTag("Komşu")
                compactTag("Kankam")
                compactTag("Tesisatçı")
            }
            .frame(height: 48)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .background(.white, in: .rect(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(.separator).opacity(0.28)))
        .shadow(color: .black.opacity(0.035), radius: 14, y: 5)
    }

    private var safeName: String {
        owner.privacySafe.displayName
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
}
