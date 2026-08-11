import SwiftUI

struct PhoneEntryView: View {
    let onAuthenticated: () -> Void
    @State private var phoneNumber = ""
    @State private var errorMessage: String?
    @State private var isShowingOTP = false
    @State private var isSending = false
    private let authService: any AuthServicing = DevelopmentAuthService()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("Telefon Numaranız")
                .font(.title2.weight(.bold))
            Text("Lütfen telefon numaranızı giriniz")
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            HStack(spacing: 8) {
                Image("TurkeyFlag")
                    .resizable()
                    .frame(width: 24, height: 24)
                Text("+90")
                    .foregroundStyle(.secondary)
                TextField("(506) 505 55 55", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .font(.title2)
                    .accessibilityIdentifier("auth.phone")
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .overlay(alignment: .bottom) { Divider() }
            .padding(.horizontal, 34)
            .padding(.top, 36)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }

            Spacer()

            Button {
                Task { await sendCode() }
            } label: {
                if isSending {
                    ProgressView().tint(.white)
                } else {
                    Text("Devam Et")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(canonicalPhone.count != 10 || isSending)
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $isShowingOTP) {
            OTPView(phoneNumber: canonicalPhone, onAuthenticated: onAuthenticated)
        }
    }

    private var canonicalPhone: String {
        let digits = phoneNumber.filter(\.isNumber)
        if digits.hasPrefix("0") { return String(digits.dropFirst()) }
        return digits
    }

    @MainActor
    private func sendCode() async {
        isSending = true
        defer { isSending = false }

        do {
            try await authService.sendVerificationCode(to: canonicalPhone)
            errorMessage = nil
            isShowingOTP = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
