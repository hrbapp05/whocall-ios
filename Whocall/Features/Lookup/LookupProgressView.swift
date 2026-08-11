import Observation
import SwiftUI

@MainActor
@Observable
final class LookupModel {
    var phase = 0
    var errorMessage: String?
    private let client = WhoCallAPIClient()

    func lookup(number: String) async -> PhoneOwner? {
        phase = 1
        do {
            let owner = try await client.lookup(number: number)
            phase = 3
            return owner
        } catch {
            errorMessage = "Sorgu tamamlanamadı. API anahtarının yerel build ayarına eklendiğini kontrol edin."
            return nil
        }
    }
}

struct LookupProgressView: View {
    let number: String
    let onResult: (PhoneOwner) -> Void
    @State private var model = LookupModel()

    var body: some View {
        VStack(spacing: 24) {
            Text(number).font(.title2.weight(.bold))
            Text("Numara Taranıyor...").foregroundStyle(.secondary)

            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.25), lineWidth: 1)
                        .frame(width: CGFloat(90 + index * 38), height: CGFloat(90 + index * 38))
                }
                Image(systemName: "phone.fill").font(.largeTitle).foregroundStyle(DesignTokens.ColorToken.brandBlue)
            }
            .frame(height: 210)

            VStack(spacing: 0) {
                progressRow("Numara Doğrulandı", active: model.phase >= 1)
                Divider()
                progressRow("Kayıtlar Taranıyor", active: model.phase >= 2)
                Divider()
                progressRow("Sonuç Hazırlanıyor", active: model.phase >= 3)
            }
            .padding(.horizontal)
            .background(DesignTokens.ColorToken.card, in: .rect(cornerRadius: 18))

            if let message = model.errorMessage {
                Text(message).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(20)
        .navigationTitle("Sorgulanıyor")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.phase = 2
            if let owner = await model.lookup(number: number) { onResult(owner) }
        }
    }

    private func progressRow(_ title: String, active: Bool) -> some View {
        HStack {
            Image(systemName: active ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(active ? DesignTokens.ColorToken.brandBlue : .secondary)
            Text(title)
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

