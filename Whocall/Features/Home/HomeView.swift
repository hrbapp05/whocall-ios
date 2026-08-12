import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(RecentLookupStore.self) private var recentLookupStore
    let onSearch: (String) -> Void
    let onRecord: (SearchRecord) -> Void
    let onPremium: () -> Void
    let onCredits: () -> Void
    @FocusState private var isSearchFocused: Bool
    @State private var phoneNumber = ""

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
                .onTapGesture { dismissKeyboard() }

            ScrollView {
                VStack(spacing: 16) {
                    HStack {
                        Text(greeting)
                            .font(.headline)
                        Spacer()
                        Button(action: onCredits) { CreditBadge() }
                            .buttonStyle(.plain)
                            .accessibilityHint("Kredi yükleme ekranını açar")
                    }

                    searchField
                        .frame(maxWidth: .infinity)

                    premiumCard

                    HStack {
                        Text("Son Sorgular").font(.headline)
                        Spacer()
                        Text("Tümünü Gör").foregroundStyle(DesignTokens.ColorToken.brandBlue)
                    }

                    recentLookups
                }
                .padding(20)
                .frame(minHeight: UIScreen.main.bounds.height - 120, alignment: .top)
                .background {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { dismissKeyboard() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .toolbar(.hidden, for: .navigationBar)
        .onChange(of: phoneNumber) { _, newValue in
            let digits = String(newValue.filter(\.isNumber).suffix(10))
            if digits != newValue { phoneNumber = digits }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image("TurkeyFlag")
                .resizable()
                .frame(width: 24, height: 24)

            TextField("Numara Tuşla", text: $phoneNumber)
                .font(.system(size: 17, weight: isSearchFocused ? .semibold : .regular))
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .focused($isSearchFocused)
                .minimumScaleFactor(0.8)

            Button {
                guard isReadyToSearch else { return }
                dismissKeyboard()
                onSearch(phoneNumber)
            } label: {
                ZStack {
                    Circle()
                        .fill(isReadyToSearch ? DesignTokens.ColorToken.brandBlue : Color(uiColor: .systemGray6))
                        .scaleEffect(isReadyToSearch ? 1 : 0.76)
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(isReadyToSearch ? .white : .black)
                }
                .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .disabled(!isReadyToSearch)
            .opacity(isSearchFocused || !phoneNumber.isEmpty ? 1 : 0)
            .frame(width: isSearchFocused || !phoneNumber.isEmpty ? 44 : 0)
            .accessibilityLabel("Numarayı sorgula")
        }
        .padding(.horizontal, 12)
        .frame(width: isSearchFocused ? 320 : 267, height: isSearchFocused ? 76 : 44)
        .background(.white, in: .rect(cornerRadius: isSearchFocused ? 24 : 22))
        .shadow(color: .black.opacity(isSearchFocused ? 0.10 : 0.05), radius: isSearchFocused ? 20 : 12, y: 6)
        .animation(.spring(duration: 0.48, bounce: 0.24), value: isSearchFocused)
        .animation(.spring(duration: 0.4, bounce: 0.32), value: isReadyToSearch)
    }

    private var premiumCard: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.68, green: 0.82, blue: 0.96))
                .frame(maxWidth: 344)
                .frame(height: 66)
                .offset(y: 31)

            Button(action: onPremium) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Hemen Sende Premium Ol!")
                            .font(.system(size: 16, weight: .bold))
                        Text("Premium abonelik alarak sınırsız sorgulama yapabilirsin!")
                            .font(.system(size: 11))
                            .lineLimit(2)
                    }
                    Spacer(minLength: 4)
                    Text("Pro Ol")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 12)
                        .frame(height: 34)
                        .background(.black, in: .capsule)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 91)
                .background(DesignTokens.ColorToken.brandBlue, in: .rect(cornerRadius: 24))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 100)
    }

    @ViewBuilder
    private var recentLookups: some View {
        if recentLookupStore.records.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "phone.badge.checkmark")
                    .font(.title2)
                    .foregroundStyle(DesignTokens.ColorToken.brandBlue)
                Text("Henüz sorgu yapmadınız")
                    .font(.subheadline.weight(.semibold))
                Text("Sorguladığınız numaralar burada görünür ve izin verdiğiniz rehber adlarıyla eşleştirilir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(22)
            .frame(maxWidth: .infinity)
            .background(.background, in: .rect(cornerRadius: 20))
        } else {
            VStack(spacing: 0) {
                ForEach(Array(recentLookupStore.records.prefix(4))) { record in
                    Button { onRecord(record) } label: {
                        SearchRecordRow(record: record).padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    if record.id != recentLookupStore.records.prefix(4).last?.id { Divider() }
                }
            }
            .padding(.horizontal)
            .background(.background, in: .rect(cornerRadius: 20))
        }
    }

    private var isReadyToSearch: Bool {
        phoneNumber.filter(\.isNumber).count == 10
    }

    private func dismissKeyboard() {
        isSearchFocused = false
    }

    private var greeting: String {
        let displayName = ProfileServiceFactory.live().currentDisplayName?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let firstName = displayName?.split(separator: " ").first else {
            return "Hoş Geldin 👋🏻"
        }
        return "Hoş Geldin, \(firstName) 👋🏻"
    }
}
