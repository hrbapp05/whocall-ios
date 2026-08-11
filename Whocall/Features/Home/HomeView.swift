import SwiftUI

struct HomeView: View {
    let onSearch: (String) -> Void
    let onRecord: (SearchRecord) -> Void
    let onPremium: () -> Void
    @State private var phoneNumber = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text("Hoş Geldin, Göktuğ 👋🏻")
                        .font(.headline)
                    Spacer()
                    Label("5", systemImage: "circle.lefthalf.filled")
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.thinMaterial, in: .capsule)
                }

                searchField

                Button(action: onPremium) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Hemen sende premium Ol!").font(.headline)
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
                    Text("Son Aramalar").font(.headline)
                    Spacer()
                    Text("Tümünü Gör").foregroundStyle(DesignTokens.ColorToken.brandBlue)
                }

                VStack(spacing: 0) {
                    ForEach(PreviewData.records) { record in
                        Button { onRecord(record) } label: { SearchRecordRow(record: record).padding(.vertical, 12) }
                            .buttonStyle(.plain)
                        if record.id != PreviewData.records.last?.id { Divider() }
                    }
                }
                .padding(.horizontal)
                .background(.background, in: .rect(cornerRadius: 20))
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
    }

    private var searchField: some View {
        HStack {
            Image("TurkeyFlag").resizable().frame(width: 24, height: 24)
            TextField("Numara Tuşla", text: $phoneNumber)
                .keyboardType(.phonePad)
            Button { onSearch(phoneNumber) } label: { Image(systemName: "magnifyingglass") }
                .disabled(phoneNumber.filter(\.isNumber).count < 10)
        }
        .padding()
        .background(.background, in: .capsule)
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

