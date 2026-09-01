import SwiftUI
import UIKit
import Combine

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
    @State private var keyboardHeight: CGFloat = 0
    @State private var clock = Date()
    @AppStorage("phoneVerificationRetryAfter") private var retryAfterTimestamp = 0.0

    init(
        onAuthenticated: @escaping () -> Void,
        authService: any AuthServicing = AuthServiceFactory.live()
    ) {
        self.onAuthenticated = onAuthenticated
        self.authService = authService
    }

    var body: some View {
        GeometryReader { proxy in
            let scale = min(proxy.size.width / referenceSize.width, 1)
            let availableReferenceHeight = (proxy.size.height - keyboardHeight) / scale
            let continueButtonY = keyboardHeight > 0
                ? min(575.5, max(405, availableReferenceHeight - 44))
                : 575.5
            let isReady = localDigits.count == 10
            let retrySeconds = remainingRetrySeconds
            let isCoolingDown = retrySeconds > 0
            let continueButtonWidth: CGFloat = isReady || isSending ? 345 : 126

            ZStack {
                DesignTokens.ColorToken.background
                    .contentShape(.rect)
                    .onTapGesture { isPhoneFocused = false }

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

                HStack(spacing: 10) {
                    Image("TurkeyFlag")
                        .resizable()
                        .frame(width: 24, height: 24)

                    TextField("(506) 505 55 55", text: formattedNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .font(.system(size: 25, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .focused($isPhoneFocused)
                        .accessibilityIdentifier("auth.phone")
                }
                .frame(width: 334, height: 38)
                .position(x: 201, y: 350)
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
                            Text(isCoolingDown ? retryLabel(seconds: retrySeconds) : "Devam Et")
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: continueButtonWidth, height: 55)
                    .background(.black, in: .capsule)
                }
                .buttonStyle(.plain)
                .disabled(!isReady || isSending || isCoolingDown)
                .opacity(isReady || isSending ? 1 : 0.46)
                .position(x: 201.5, y: continueButtonY)
                .animation(.spring(response: 0.52, dampingFraction: 0.78), value: isReady)
                .animation(.easeInOut(duration: 0.24), value: keyboardHeight)
                .accessibilityIdentifier("auth.phone.continue")
            }
            .frame(width: referenceSize.width, height: referenceSize.height)
            .scaleEffect(scale, anchor: .top)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
        .ignoresSafeArea(.container)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)) {
            updateKeyboardHeight(from: $0)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            keyboardHeight = 0
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            clock = date
            if retryAfterTimestamp > 0, date.timeIntervalSince1970 >= retryAfterTimestamp {
                retryAfterTimestamp = 0
            }
        }
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
    }

    private var formattedNumber: Binding<String> {
        Binding(
            get: { TurkishPhoneNumberFormatter.display(localDigits) },
            set: { phoneNumber = String($0.filter(\.isNumber).prefix(10)) }
        )
    }

    private var localDigits: String { String(phoneNumber.filter(\.isNumber).prefix(10)) }
    private var e164Number: String { "+90\(localDigits)" }
    private var remainingRetrySeconds: Int {
        max(0, Int(ceil(retryAfterTimestamp - clock.timeIntervalSince1970)))
    }

    private var isShowingOTP: Binding<Bool> {
        Binding(
            get: { verificationID != nil },
            set: { if !$0 { verificationID = nil } }
        )
    }

    private func updateKeyboardHeight(from notification: Notification) {
        guard let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        withAnimation(.easeInOut(duration: 0.24)) {
            keyboardHeight = max(0, UIScreen.main.bounds.height - frame.minY)
        }
    }

    private func retryLabel(seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return String(format: "%02d:%02d sonra dene", minutes, remainder)
    }

    @MainActor
    private func sendCode() async {
        guard !isSending, remainingRetrySeconds == 0 else { return }
        isPhoneFocused = false
        isSending = true
        defer { isSending = false }

        do {
            verificationID = try await authService.sendVerificationCode(to: e164Number)
            errorMessage = nil
        } catch {
            if let authError = error as? AuthError,
               let cooldown = PhoneVerificationRetryPolicy.cooldown(for: authError) {
                let now = Date()
                clock = now
                retryAfterTimestamp = now.addingTimeInterval(cooldown).timeIntervalSince1970
            }
            errorMessage = error.localizedDescription
        }
    }
}
