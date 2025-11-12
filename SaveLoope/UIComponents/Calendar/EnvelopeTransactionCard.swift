import SwiftUI
import SwiftData

struct EnvelopeTransactionCard: View {
    let envelope: Envelope?
    let transactions: [TransactionRecord]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            EnvelopeCardHeader(envelopeName: envelope?.name ?? "calendar.envelope_unspecified".localized, count: transactions.count) // 봉투 미지정

            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, transaction in
                    TransactionRowView(
                        transaction: transaction,
                        showDivider: index < transactions.count - 1
                    )
                }
            }
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color("DividerColor"), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color("DividerColor"), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}

struct EnvelopeCardHeader: View {
    let envelopeName: String
    let count: Int

    var body: some View {
        HStack {
            Image(systemName: "envelope.fill")
                .font(.caption)
                .foregroundColor(.white)
            Text(envelopeName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Text(String(format: "calendar.transaction_count".localized, count)) // %d건
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.5), Color.blue.opacity(0.4)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
    }
}
