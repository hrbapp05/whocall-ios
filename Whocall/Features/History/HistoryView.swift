import SwiftUI

struct HistoryView: View {
    @Environment(RecentLookupStore.self) private var recentLookupStore

    var body: some View {
        NavigationStack {
            List {
                if recentLookupStore.records.isEmpty {
                    ContentUnavailableView(
                        "Sorgu Geçmişi Boş",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("WhoCall içinde sorguladığınız numaralar burada görünür.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    Section("WhoCall Sorguları") {
                        ForEach(recentLookupStore.records) { record in
                            NavigationLink {
                                PersonDetailView(
                                    name: record.displayName,
                                    number: record.phoneNumber,
                                    onComments: {}
                                )
                            } label: {
                                SearchRecordRow(record: record)
                            }
                        }
                        .onDelete(perform: recentLookupStore.remove)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Geçmiş Sorgular")
            .toolbar {
                if !recentLookupStore.records.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Temizle", role: .destructive) { recentLookupStore.clear() }
                    }
                }
            }
        }
    }
}
