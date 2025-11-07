import SwiftUI

struct TransactionSummaryHeader: View {
    let totalIncome: Int
    let totalExpense: Int

    private func formatAmount(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    var body: some View {
        HStack(spacing: 30) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("수입")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("+\(formatAmount(totalIncome))원")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.red)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("지출")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("-\(formatAmount(totalExpense))원")
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
