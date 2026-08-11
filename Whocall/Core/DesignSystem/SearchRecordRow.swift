import SwiftUI

struct SearchRecordRow: View {
    let record: SearchRecord

    var body: some View {
        HStack(spacing: 8) {
            Text(record.initials)
                .font(.caption.weight(.bold))
                .frame(width: 50, height: 50)
                .background(record.isWarning ? Color.red.opacity(0.25) : DesignTokens.ColorToken.mint)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 5) {
                Text(record.phoneNumber)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.displayName)
                    .font(.subheadline.weight(.bold))
                    .lineLimit(1)
            }
            Spacer()
            Text(record.time)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

