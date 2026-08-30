import SwiftUI
import UIKit

struct NotificationSettingsView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var authorizationState = NotificationAuthorizationState.unavailable
    @State private var isEnabled = false
    @State private var isUpdating = false
    @State private var showsSystemSettingsAlert = false

    var body: some View {
        List {
            Section {
                Toggle("Bildirimleri Al", isOn: notificationBinding)
                    .disabled(isUpdating)

                HStack {
                    Label("İzin Durumu", systemImage: statusSymbol)
                    Spacer()
                    Text(authorizationState.title)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                if isUpdating {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Bildirim tercihiniz güncelleniyor…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("WhoCall Bildirimleri")
            } footer: {
                Text("Hesabınızla ilgili önemli gelişmeleri ve WhoCall duyurularını alabilirsiniz. Bildirimleri kapattığınızda bu cihaz sunucu listesinden de kaldırılır.")
            }

            Section {
                Button {
                    openSystemNotificationSettings()
                } label: {
                    HStack {
                        Label("iPhone Bildirim Ayarlarını Aç", systemImage: "gear")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
            } footer: {
                Text("Ses, rozet ve kilit ekranı seçenekleri iPhone Ayarları üzerinden yönetilir.")
            }
        }
        .navigationTitle("Bildirim Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await refreshState()
        }
        .alert("Bildirim İzni Gerekli", isPresented: $showsSystemSettingsAlert) {
            Button("Vazgeç", role: .cancel) {}
            Button("Ayarları Aç", action: openSystemNotificationSettings)
        } message: {
            Text("WhoCall bildirimleri iPhone ayarlarından kapatılmış. Bildirimleri açmak için WhoCall bildirim ayarlarına gidin.")
        }
    }

    private var notificationBinding: Binding<Bool> {
        Binding(
            get: { isEnabled },
            set: { newValue in
                guard !isUpdating else { return }
                updatePreference(newValue)
            }
        )
    }

    private func updatePreference(_ newValue: Bool) {
        isUpdating = true
        Task {
            let state = await NotificationRegistrationService.shared.setEnabled(newValue)
            authorizationState = state
            let userID = ProfileServiceFactory.live().currentUserID
            isEnabled = NotificationPreference.isEnabled(userID: userID) && state.isAuthorized
            isUpdating = false
            if newValue && !state.isAuthorized {
                showsSystemSettingsAlert = state == .denied
            }
        }
    }

    @MainActor
    private func refreshState() async {
        let state = await NotificationRegistrationService.shared.authorizationState()
        let userID = ProfileServiceFactory.live().currentUserID
        authorizationState = state
        isEnabled = NotificationPreference.isEnabled(userID: userID) && state.isAuthorized
    }

    private func openSystemNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    private var statusSymbol: String {
        switch authorizationState {
        case .enabled: "checkmark.circle.fill"
        case .denied: "exclamationmark.triangle.fill"
        case .notDetermined: "questionmark.circle"
        case .unavailable: "minus.circle"
        }
    }

    private var statusColor: Color {
        switch authorizationState {
        case .enabled: DesignTokens.ColorToken.success
        case .denied: .orange
        case .notDetermined, .unavailable: .secondary
        }
    }
}
