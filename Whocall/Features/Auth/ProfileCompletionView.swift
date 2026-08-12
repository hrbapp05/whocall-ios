import SwiftUI

struct ProfileCompletionView: View {
    let onComplete: () -> Void
    private let profileService: any ProfileServicing

    @FocusState private var focusedField: Field?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(
        onComplete: @escaping () -> Void,
        profileService: any ProfileServicing = ProfileServiceFactory.live()
    ) {
        self.onComplete = onComplete
        self.profileService = profileService
    }

    var body: some View {
        ZStack {
            DesignTokens.ColorToken.background
                .ignoresSafeArea()
                .contentShape(.rect)
                .onTapGesture { focusedField = nil }

            VStack(spacing: 0) {
                Image("WhoCallLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 26)
                    .padding(.top, 34)

                Spacer()

                Text("Sizi Tanıyalım")
                    .font(.system(size: 28, weight: .bold))
                    .figmaEntrance(delay: 0.05, distance: 12)

                Text("Doğruladığınız numara sorgulandığında göstermek üzere adınızı ve soyadınızı girin.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)

                VStack(spacing: 14) {
                    profileField("Adınız", text: $firstName, contentType: .givenName, field: .firstName)
                    profileField("Soyadınız", text: $lastName, contentType: .familyName, field: .lastName)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .figmaEntrance(delay: 0.12, distance: 14)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                }

                Button {
                    focusedField = nil
                    Task { await save() }
                } label: {
                    Group {
                        if isSaving {
                            ProgressView().tint(.white)
                        } else {
                            Text("Devam Et")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isValid || isSaving)
                .opacity(isValid ? 1 : 0.46)
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()
            }
        }
        .interactiveDismissDisabled()
        .task { focusedField = .firstName }
    }

    private var isValid: Bool {
        !normalizedFirstName.isEmpty && !normalizedLastName.isEmpty
    }

    private var normalizedFirstName: String {
        firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedLastName: String {
        lastName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func profileField(
        _ title: String,
        text: Binding<String>,
        contentType: UITextContentType,
        field: Field
    ) -> some View {
        TextField(title, text: text)
            .textContentType(contentType)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .focused($focusedField, equals: field)
            .submitLabel(field == .firstName ? .next : .done)
            .onSubmit {
                focusedField = field == .firstName ? .lastName : nil
            }
            .padding(.horizontal, 18)
            .frame(height: 56)
            .background(.white, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(focusedField == field ? .black : Color(.separator).opacity(0.25), lineWidth: 1)
            }
    }

    @MainActor
    private func save() async {
        guard isValid else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            try await profileService.updateProfile(
                firstName: normalizedFirstName,
                lastName: normalizedLastName
            )
            onComplete()
        } catch {
            errorMessage = "Profil kaydedilemedi. Lütfen bağlantınızı kontrol edip tekrar deneyin."
        }
    }
}

private extension ProfileCompletionView {
    enum Field: Hashable {
        case firstName
        case lastName
    }
}
