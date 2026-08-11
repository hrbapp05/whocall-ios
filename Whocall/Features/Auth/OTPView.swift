import SwiftUI

struct OTPView: View {
    let phoneNumber: String
    let onAuthenticated: () -> Void
    @State private var code = ""
    @State private var errorMessage: String?
    private let authService: any AuthServicing = DevelopmentAuthService()

    var body: some View {
        VStack {
            Spacer()
            Text("Doğrulama Kodu")
                .font(.title2.weight(.bold))
            Text("Sms olarak gönderilen doğrulama kodunu giriniz.")
                .foregroundStyle(.secondary)

            TextField("00000", text: $code)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.largeTitle.monospacedDigit())
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 310)
                .padding(.top, 20)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.filter(\.isNumber).prefix(5))
                }

            if let errorMessage {
                Text(errorMessage).font(.footnote).foregroundStyle(.red)
            }

            Spacer()
            Button("Devam Et") {
                Task { await verify() }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(code.count != 5)
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @MainActor
    private func verify() async {
        do {
            try await authService.verify(code: code)
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

