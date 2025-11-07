import SwiftUI
import SwiftData

struct TransactionRowView: View {
    let transaction: TransactionRecord
    let showDivider: Bool

    private func formatAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: transaction.type == .income ? "plus.circle.fill" : "minus.circle.fill")
                    .font(.title3)
                    .foregroundColor(transaction.type == .income ? .blue : .red)

                VStack(alignment: .leading, spacing: 3) {
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    } else {
                        Text(transaction.type == .income ? "수입" : "지출")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                Spacer()

                Text("\(transaction.type == .income ? "+" : "-")\(formatAmount(transaction.amount))원")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(transaction.type == .income ? .blue : .red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)

            if showDivider {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}
