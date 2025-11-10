import SwiftUI
import SwiftData

struct DayTransactionSheet: View {
    let date: Date
    let transactions: [TransactionRecord]

    private var formattedDate: String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year,
              let month = components.month,
              let day = components.day else {
            return ""
        }
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

    // 한 번만 계산하여 재사용
    private var transactionTotals: (income: Double, expense: Double) {
        var income: Double = 0
        var expense: Double = 0
        
        for transaction in transactions {
            if transaction.type == .income {
                income += transaction.amount
            } else {
                expense += transaction.amount
            }
        }
        
        return (income, expense)
    }
    
    private var totalIncome: Double {
        transactionTotals.income
    }

    private var totalExpense: Double {
        transactionTotals.expense
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
