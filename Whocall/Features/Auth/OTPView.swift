import SwiftUI

struct OTPView: View {
    private let referenceSize = CGSize(width: 402, height: 874)
    private let codeLength = 6

    let verificationID: String
    let phoneNumber: String
    let onAuthenticated: () -> Void
    private let authService: any AuthServicing

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isCodeFocused: Bool
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isVerifying = false
    @State private var cursorVisible = true

    init(
        verificationID: String,
        phoneNumber: String,
        onAuthenticated: @escaping () -> Void,
        authService: any AuthServicing = AuthServiceFactory.live()
    ) {
        self.verificationID = verificationID
        self.phoneNumber = phoneNumber
        self.onAuthenticated = onAuthenticated
        self.authService = authService
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / referenceSize.width, 1)
            let availableReferenceHeight = proxy.size.height / scale
            let continueButtonY = min(575.5, availableReferenceHeight - 47.5)

            ZStack {
                DesignTokens.ColorToken.background
                    .contentShape(.rect)
                    .onTapGesture { isCodeFocused = false }

                FigmaBackButton(action: { dismiss() })
                    .position(x: 38, y: 80)

                VStack(spacing: 5) {
                    Text("Doğrulama Kodu")
                        .font(.system(size: 20, weight: .bold))
                    Text("Sms olarak gönderilen doğrulama kodunu giriniz.")
                        .font(.system(size: 16))
                }
                .frame(width: 370, height: 48)
                .position(x: 201, y: 279)
                .figmaEntrance(delay: 0.04, distance: 10)

                HStack(spacing: 10) {
                    ForEach(0..<codeLength, id: \.self) { index in
                        OTPDigitBox(
                            digit: digit(at: index),
                            isFocused: isCodeFocused && index == min(code.count, codeLength - 1),
                            cursorVisible: cursorVisible && code.count == index
                        )
                    }
                }
                .frame(width: 362, height: 52)
                .position(x: 201, y: 350)
                .figmaEntrance(delay: 0.10, distance: 10)
                .contentShape(.rect)
                .onTapGesture { isCodeFocused = true }

                TextField("", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($isCodeFocused)
                    .opacity(0.001)
                    .frame(width: 1, height: 1)
                    .position(x: 201, y: 408)
                    .onChange(of: code) { _, newValue in
                        code = String(newValue.filter(\.isNumber).prefix(codeLength))
                        errorMessage = nil
                    }
                    .accessibilityIdentifier("auth.otp")

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(width: 340)
                        .position(x: 201, y: 420)
                }

                Button {
                    Task { await verify() }
                } label: {
                    Group {
                        if isVerifying {
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
                .disabled(code.count != codeLength || isVerifying)
                .opacity(code.count == codeLength ? 1 : 0.46)
                .position(x: 201.5, y: continueButtonY)
                .accessibilityIdentifier("auth.otp.continue")
            }
            .frame(width: referenceSize.width, height: referenceSize.height)
            .scaleEffect(scale, anchor: .top)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .animation(.easeOut(duration: 0.22), value: proxy.size.height)
        }
        .ignoresSafeArea(.container)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            try? await Task.sleep(for: .milliseconds(300))
            isCodeFocused = true
            withAnimation(.easeInOut(duration: 0.48).repeatForever(autoreverses: true)) {
                cursorVisible.toggle()
            }
        }
    }

    private func digit(at index: Int) -> Character? {
        guard code.indices.contains(code.index(code.startIndex, offsetBy: index, limitedBy: code.endIndex) ?? code.endIndex) else {
            return nil
        }
        let codeIndex = code.index(code.startIndex, offsetBy: index)
        return code[codeIndex]
    }

    @MainActor
    private func verify() async {
        isVerifying = true
        defer { isVerifying = false }

        do {
            try await authService.verify(verificationID: verificationID, code: code)
            onAuthenticated()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct OTPDigitBox: View {
    let digit: Character?
    let isFocused: Bool
    let cursorVisible: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? .black : Color(red: 223 / 255, green: 225 / 255, blue: 231 / 255),
                    lineWidth: 1
                )

            if let digit {
                Text(String(digit))
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
            } else if isFocused && cursorVisible {
                Capsule()
                    .fill(.black)
                    .frame(width: 1.5, height: 27)
            }
        }
        .frame(width: 52, height: 52)
    }
}
