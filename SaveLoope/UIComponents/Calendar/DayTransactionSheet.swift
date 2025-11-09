import SwiftUI
import SwiftData

struct DayTransactionSheet: View {
    let date: Date
    let transactions: [TransactionRecord]

    private var formattedDate: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        return "\(year)년 \(month)월 \(day)일"
    }

    // 봉투별로 거래내역 그룹핑
    private var groupedTransactions: [(envelope: Envelope?, transactions: [TransactionRecord])] {
        let grouped = Dictionary(grouping: transactions) { $0.envelope }
        return grouped.map { (envelope: $0.key, transactions: $0.value) }
            .sorted { first, second in
                if first.envelope == nil { return false }
                if second.envelope == nil { return true }
                return (first.envelope?.name ?? "") < (second.envelope?.name ?? "")
            }
    }

    private var totalIncome: Double {
        transactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Double {
        transactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationView {
            Group {
                if transactions.isEmpty {
                    EmptyTransactionView()
                } else {
                    VStack(spacing: 0) {
                        TransactionSummaryHeader(totalIncome: totalIncome, totalExpense: totalExpense)

                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(groupedTransactions, id: \.envelope?.id) { group in
                                    EnvelopeTransactionCard(
                                        envelope: group.envelope,
                                        transactions: group.transactions
                                    )
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(formattedDate)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
