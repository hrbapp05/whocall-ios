import SwiftUI

struct PhoneEntryView: View {
    private let referenceSize = CGSize(width: 402, height: 874)

    let onAuthenticated: () -> Void
    private let authService: any AuthServicing

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isPhoneFocused: Bool
    @State private var phoneNumber = ""
    @State private var errorMessage: String?
    @State private var verificationID: String?
    @State private var isSending = false

    init(
        onAuthenticated: @escaping () -> Void,
        authService: any AuthServicing = AuthServiceFactory.live()
    ) {
        self.onAuthenticated = onAuthenticated
        self.authService = authService
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(
                proxy.size.width / referenceSize.width,
                proxy.size.height / referenceSize.height
            )

            ZStack {
                DesignTokens.ColorToken.background

                FigmaBackButton(action: { dismiss() })
                    .position(x: 38, y: 80)

                VStack(spacing: 5) {
                    Text("Telefon Numaranız")
                        .font(.system(size: 20, weight: .bold))
                    Text("Lütfen telefon numaranızı giriniz")
                        .font(.system(size: 16))
                }
                .frame(width: 300, height: 48)
                .position(x: 201, y: 261)
                .figmaEntrance(delay: 0.04, distance: 10)

                HStack(spacing: 8) {
                    Image("TurkeyFlag")
                        .resizable()
                        .frame(width: 24, height: 24)

                    TextField("(506) 505 55 55", text: formattedNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .font(.system(size: 28, weight: .semibold))
                        .focused($isPhoneFocused)
                        .accessibilityIdentifier("auth.phone")
                }
                .frame(width: 245, height: 34)
                .position(x: 211.5, y: 350)
                .figmaEntrance(delay: 0.10, distance: 10)

                Rectangle()
                    .fill(Color(red: 223 / 255, green: 225 / 255, blue: 231 / 255))
                    .frame(width: 334, height: 1)
                    .position(x: 201, y: 383)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(width: 340)
                        .position(x: 201, y: 420)
                }

                Button {
                    Task { await sendCode() }
                } label: {
                    Group {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Devam Et")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 345, height: 55)
                    .background(.black, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(localDigits.count != 10 || isSending)
                .opacity(localDigits.count == 10 ? 1 : 0.46)
                .position(x: 201.5, y: 575.5)
                .accessibilityIdentifier("auth.phone.continue")
            }
            .frame(width: referenceSize.width, height: referenceSize.height)
            .scaleEffect(scale)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: isShowingOTP) {
            if let verificationID {
                OTPView(
                    verificationID: verificationID,
                    phoneNumber: e164Number,
                    onAuthenticated: onAuthenticated,
                    authService: authService
                )
            }
        }
        .task {
            try? await Task.sleep(for: .milliseconds(320))
            isPhoneFocused = true
        }
    }

    private var formattedNumber: Binding<String> {
        Binding(
            get: { formatLocalNumber(localDigits) },
            set: { phoneNumber = String($0.filter(\.isNumber).prefix(10)) }
        )
    }

    private var localDigits: String { String(phoneNumber.filter(\.isNumber).prefix(10)) }
    private var e164Number: String { "+90\(localDigits)" }

    private var isShowingOTP: Binding<Bool> {
        Binding(
            get: { verificationID != nil },
            set: { if !$0 { verificationID = nil } }
        )
    }

    private func formatLocalNumber(_ digits: String) -> String {
        guard !digits.isEmpty else { return "" }
        var result = "(\(digits.prefix(3))"
        if digits.count >= 3 { result += ")" }
        if digits.count > 3 { result += " \(digits.dropFirst(3).prefix(3))" }
        if digits.count > 6 { result += " \(digits.dropFirst(6).prefix(2))" }
        if digits.count > 8 { result += " \(digits.dropFirst(8).prefix(2))" }
        return result
    }

    @MainActor
    private func sendCode() async {
        isSending = true
        defer { isSending = false }

        do {
            verificationID = try await authService.sendVerificationCode(to: e164Number)
            errorMessage = nil
            isPhoneFocused = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
