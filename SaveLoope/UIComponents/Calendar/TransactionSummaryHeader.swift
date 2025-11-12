import SwiftUI

struct TransactionSummaryHeader: View {
    let totalIncome: Double
    let totalExpense: Double
    @ObservedObject private var currencyManager = CurrencyManager.shared


    var body: some View {
        HStack(spacing: 30) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("transaction.type.income".localized) // 수입
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("+\(totalIncome.formattedCurrency)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("transaction.type.expense".localized) // 지출
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("-\(totalExpense.formattedCurrency)")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.08))
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
