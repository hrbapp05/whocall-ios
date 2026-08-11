import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Bugün") {
                    ForEach(PreviewData.records.prefix(3)) { record in
                        NavigationLink { PersonDetailView(name: record.displayName, number: record.phoneNumber, onComments: {}) } label: { SearchRecordRow(record: record) }
                    }
                }
                Section("Dün") {
                    ForEach(PreviewData.records) { record in SearchRecordRow(record: record) }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Geçmiş Sorgular")
        }
    }
}

