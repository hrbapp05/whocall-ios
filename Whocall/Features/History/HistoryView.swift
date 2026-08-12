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
                                HistoryPersonDetail(record: record)
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

private struct HistoryPersonDetail: View {
    let record: SearchRecord
    @State private var destination: HistoryPersonDestination?

    var body: some View {
        PersonDetailView(
            name: record.displayName,
            number: record.phoneNumber,
            onComments: { destination = .comments },
            onAddComment: { destination = .addComment },
            onCredits: { destination = .credits }
        )
        .navigationDestination(item: $destination) { destination in
            switch destination {
            case .comments:
                CommentsView(personName: record.displayName, phoneNumber: record.phoneNumber)
            case .addComment:
                CommentsView(
                    personName: record.displayName,
                    phoneNumber: record.phoneNumber,
                    startsComposing: true
                )
            case .credits:
                CreditsView()
            }
        }
    }
}

private enum HistoryPersonDestination: Hashable {
    case comments
    case addComment
    case credits
}
