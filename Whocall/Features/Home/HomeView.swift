import SwiftUI

struct HomeView: View {
    @Environment(RecentLookupStore.self) private var recentLookupStore
    let onSearch: (String) -> Void
    let onRecord: (SearchRecord) -> Void
    let onPremium: () -> Void
    @FocusState private var isSearchFocused: Bool
    @State private var phoneNumber = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text(greeting)
                        .font(.headline)
                    Spacer()
                    CreditBadge()
                }

                searchField

                Button(action: onPremium) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hemen Sende Premium Ol!").font(.headline)
                            Text("Premium abonelik alarak sınırsız sorgulama yapabilirsin!").font(.caption)
                        }
                        Spacer()
                        Text("Pro Ol").font(.caption.weight(.bold)).padding(10).background(.black, in: .capsule)
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .background(DesignTokens.ColorToken.brandBlue, in: .rect(cornerRadius: 18))
                }
                .buttonStyle(.plain)

                HStack {
                    Text("Son Sorgular").font(.headline)
                    Spacer()
                    Text("Tümünü Gör").foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }

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
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .scrollDismissesKeyboard(.interactively)
        .toolbar(.hidden, for: .navigationBar)
    }

    private var searchField: some View {
        HStack {
            Image("TurkeyFlag").resizable().frame(width: 24, height: 24)
            TextField("Numara Tuşla", text: $phoneNumber)
                .keyboardType(.phonePad)
                .focused($isSearchFocused)
            Button {
                isSearchFocused = false
                onSearch(phoneNumber)
            } label: { Image(systemName: "magnifyingglass") }
                .disabled(phoneNumber.filter(\.isNumber).count < 10)
        }
        .padding()
        .background(.background, in: .capsule)
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
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
