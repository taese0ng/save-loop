import SwiftUI

struct MonthSummaryView: View {
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double
    @ObservedObject private var currencyManager = CurrencyManager.shared


    var body: some View {
        HStack(spacing: 20) {
            // 왼쪽 열: 총 수입 + 총 지출 (2행)
            VStack(alignment: .leading, spacing: 8) {
                // 총 수입
                HStack(spacing: 8) {
                    Text("총 수입")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .frame(width: 50, alignment: .leading)
                    Text("+\(totalIncome.formattedCurrency)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                // 총 지출
                HStack(spacing: 8) {
                    Text("총 지출")
                        .font(.caption)
                        .foregroundColor(Color("SecondaryText"))
                        .frame(width: 50, alignment: .leading)
                    Text("-\(totalExpense.formattedCurrency)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .frame(height: 40)

            // 오른쪽: 총액
            VStack(alignment: .leading, spacing: 4) {
                Text("총액")
                    .font(.caption)
                    .foregroundColor(Color("SecondaryText"))
                Text("\(balance >= 0 ? "+" : "")\(balance.formattedCurrency)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(balance >= 0 ? .blue : .red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("Separator"))
        )
    }
}
