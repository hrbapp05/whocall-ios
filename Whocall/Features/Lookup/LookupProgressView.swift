import Observation
import SwiftUI

@MainActor
@Observable
final class LookupModel {
    var phase = 0
    var errorMessage: String?
    private let client = WhoCallAPIClient()

    func lookup(number: String) async -> PhoneOwner? {
        do {
            return try await client.lookup(number: number)
        } catch {
            errorMessage = "Sorgu tamamlanamadı. API anahtarının yerel build ayarına eklendiğini kontrol edin."
            return nil
        }
    }
}

struct LookupProgressView: View {
    @Environment(\.dismiss) private var dismiss
    let number: String
    let onResult: (PhoneOwner) -> Void
    @State private var model = LookupModel()

    var body: some View {
        VStack(spacing: 0) {
            customHeader

            HStack(spacing: 8) {
                Image("TurkeyFlag").resizable().frame(width: 18, height: 18)
                Text(displayNumber)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.top, 22)
            Text("Numara Taranıyor...")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 6)

            ScannerRadar()
                .frame(height: 250)
                .figmaEntrance(delay: 0.05, distance: 8)

            progressCard
                .padding(.horizontal, 20)
                .figmaEntrance(delay: 0.16, distance: 18)

            Spacer(minLength: 24)

            infoCard
                .padding(.horizontal, 20)

            Button("Sorguyu İptal Et") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .padding(.bottom, 18)
        }
        .background(DesignTokens.ColorToken.brandBlue.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await beginLookup() }
    }

    private var customHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(width: 36, height: 36)
                    .background(.white, in: .circle)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Sorgulanıyor")
                .font(.headline)
                .foregroundStyle(.white)

            Spacer()

            ToolbarCreditBadge()
                .background(.white, in: .capsule)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .frame(height: 52)
    }

    private var displayNumber: String {
        let digits = number.filter(\.isNumber)
        guard digits.count >= 10 else { return number }
        let value = String(digits.suffix(10))
        return "\(value.prefix(3)) \(value.dropFirst(3).prefix(3)) \(value.dropFirst(6).prefix(2)) \(value.suffix(2))"
    }

    private var progressCard: some View {
        VStack(spacing: 0) {
            progressRow("Numara Doğrulandı", step: 1)
            Divider()
            progressRow("Kayıtlar Taranıyor", step: 2)
            Divider()
            progressRow("Sonuç Hazırlanıyor", step: 3)
        }
        .padding(.horizontal, 16)
        .background(.white, in: .rect(cornerRadius: 20))
        .shadow(color: .black.opacity(0.10), radius: 24, y: 12)
    }

    private func progressRow(_ title: String, step: Int) -> some View {
        HStack(spacing: 10) {
            Group {
                if model.phase > step || (model.phase == 3 && step == 3) {
                    Image(systemName: "checkmark.circle.fill")
                } else if model.phase == step {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "circle")
                }
            }
            .frame(width: 22, height: 22)
            .foregroundStyle(model.phase >= step ? DesignTokens.ColorToken.brandBlue : .primary)
            Text(title).font(.subheadline.weight(.medium))
            Spacer()
        }
        .frame(height: 52)
    }

    private var infoCard: some View {
        HStack(spacing: 12) {
            Image("ScannerInfo").resizable().scaledToFit().frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 5) {
                Text("Topluluk kayıtları ve güven sinyalleri karşılaştırılıyor.")
                    .font(.subheadline.weight(.medium))
                Text("Bu işlem genellikle birkaç saniye sürer.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .frame(minHeight: 70)
        .background(.white, in: .rect(cornerRadius: 18))
        .figmaEntrance(delay: 0.24, distance: 14)
    }

    @MainActor
    private func beginLookup() async {
        withAnimation { model.phase = 1 }
        try? await Task.sleep(for: .milliseconds(650))
        withAnimation { model.phase = 2 }
        if let owner = await model.lookup(number: number) {
            withAnimation { model.phase = 3 }
            try? await Task.sleep(for: .milliseconds(450))
            onResult(owner)
        }
    }
}

private struct ScannerRadar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var rotation = 0.0

    var body: some View {
        ZStack {
            ForEach(0..<4, id: \.self) { index in
                Circle()
                    .stroke(.white.opacity(0.28 + Double(index) * 0.1), lineWidth: 1)
                    .background(Circle().fill(.white.opacity(0.035)))
                    .frame(width: CGFloat(92 + index * 40), height: CGFloat(92 + index * 40))
                    .scaleEffect(reduceMotion ? 1 : (pulse ? 1.04 : 0.96))
                    .opacity(reduceMotion ? 1 : (pulse ? 0.85 : 0.55))
            }
            Circle()
                .trim(from: 0.08, to: 0.72)
                .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 174, height: 174)
                .rotationEffect(.degrees(rotation))
            Circle().fill(.white.opacity(0.22)).frame(width: 92, height: 92)
            Image(systemName: "phone.fill")
                .font(.system(size: 42, weight: .medium))
                .foregroundStyle(.white)
                .shadow(color: .white.opacity(0.45), radius: 14)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) { pulse = true }
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) { rotation = 360 }
        }
    }
}
