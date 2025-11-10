import SwiftUI
import SwiftData

struct TransactionRowView: View {
    let transaction: TransactionRecord
    let showDivider: Bool
    @ObservedObject private var currencyManager = CurrencyManager.shared


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
                            .foregroundColor(Color("SecondaryText"))
                    }
                }

                Spacer()

                Text("\(transaction.type == .income ? "+" : "-")\(transaction.amount.formattedCurrency)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(transaction.type == .income ? .blue : .red)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if showDivider {
                Divider()
                    .padding(.leading, 56)
            }
        }
    }
}
