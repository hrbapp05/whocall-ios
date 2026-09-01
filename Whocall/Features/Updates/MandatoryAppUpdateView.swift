import SwiftUI

struct MandatoryAppUpdateView: View {
    let update: RequiredAppUpdate
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPresented = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.42)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.ColorToken.brandBlue.opacity(0.10))
                        .frame(width: 132, height: 132)
                    Circle()
                        .stroke(DesignTokens.ColorToken.brandBlue.opacity(0.18), lineWidth: 1)
                        .frame(width: 164, height: 164)
                    Image("LoginAppIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 92, height: 92)
                        .clipShape(.rect(cornerRadius: 22))
                        .shadow(color: DesignTokens.ColorToken.brandBlue.opacity(0.22), radius: 22, y: 10)
                }

                Text("Yeni Sürüm Hazır")
                    .font(.system(size: 25, weight: .bold))
                    .padding(.top, 26)

                Text("WhoCall \(update.version) sürümünü kullanmaya devam etmek için uygulamayı güncellemeniz gerekiyor.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.top, 10)

                Button("Şimdi Güncelle") {
                    openURL(update.storeURL)
                }
                .buttonStyle(PrimaryButtonStyle(background: DesignTokens.ColorToken.brandBlue))
                .padding(.top, 28)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 30)
            .frame(maxWidth: 360)
            .background(.white, in: .rect(cornerRadius: 30))
            .shadow(color: .black.opacity(0.20), radius: 34, y: 18)
            .padding(.horizontal, 22)
            .scaleEffect(reduceMotion || isPresented ? 1 : 0.88)
            .opacity(isPresented ? 1 : 0)
        }
        .accessibilityAddTraits(.isModal)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.24)) {
                isPresented = true
            }
        }
    }
}
