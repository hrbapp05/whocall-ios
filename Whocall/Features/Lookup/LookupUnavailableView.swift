import SwiftUI

enum LookupUnavailableReason: Hashable {
    case hidden
    case requesterHidden
    case notFound

    var title: String {
        switch self {
        case .hidden: "Bu Kullanıcı Görünürlüğünü Kapattı"
        case .requesterHidden: "Sorgulamak İçin Görünürlüğü Açın"
        case .notFound: "Sonuç Bulunamadı"
        }
    }

    var message: String {
        switch self {
        case .hidden:
            "Bu numaranın sahibi arama sonuçlarında görünmemeyi tercih ediyor."
        case .requesterHidden:
            "Görünürlüğünüz kapalıyken başka numaraları sorgulayamazsınız. Profil sekmesinden görünürlüğünüzü açarak devam edebilirsiniz."
        case .notFound:
            "Bu numara WhoCall topluluğunda veya veri tabanımızda kayıtlı değil."
        }
    }

    var symbol: String {
        switch self {
        case .hidden: "eye.slash.fill"
        case .requesterHidden: "person.crop.circle.badge.exclamationmark"
        case .notFound: "magnifyingglass"
        }
    }

    var actionTitle: String {
        self == .requesterHidden ? "Profilde Görünürlüğü Aç" : "Yeni Sorgu Yap"
    }
}

struct LookupUnavailableView: View {
    let reason: LookupUnavailableReason
    let number: String
    let onNewLookup: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignTokens.ColorToken.brandBlue.opacity(0.10))
                    .frame(width: 124, height: 124)
                Circle()
                    .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.16), lineWidth: 1)
                    .frame(width: 154, height: 154)
                Image(systemName: reason.symbol)
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .figmaEntrance(delay: 0.03, distance: 12)

            Text(reason.title)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 34)

            Text(displayNumber)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 10)

            Text(reason.message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 12)

            Spacer()

            Button(reason.actionTitle, action: onNewLookup)
                .buttonStyle(PrimaryButtonStyle(background: DesignTokens.ColorToken.brandBlue))
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                .accessibilityIdentifier("lookup.unavailable.new")
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var navigationTitle: String {
        switch reason {
        case .hidden: "Gizli Kullanıcı"
        case .requesterHidden: "Görünürlük Gerekli"
        case .notFound: "Sonuç Bulunamadı"
        }
    }

    private var displayNumber: String {
        let digits = number.filter(\.isNumber)
        guard digits.count >= 10 else { return number }
        let value = String(digits.suffix(10))
        return "+90 \(value.prefix(3)) \(value.dropFirst(3).prefix(3)) \(value.dropFirst(6).prefix(2)) \(value.suffix(2))"
    }
}
