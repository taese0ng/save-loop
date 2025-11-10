import SwiftUI
import SwiftData
import Foundation


struct DetailEnvelopeView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Bindable var envelope: Envelope
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Query private var transactions: [TransactionRecord]
    @State private var selectedTransaction: TransactionRecord? = nil
    @State private var showingEditSheet: Bool = false
    @State private var shouldDismiss: Bool = false
    
    private let dateFormatter: DateFormatter = {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter
    }()
    
    
    var filteredTransactions: [TransactionRecord] {
        transactions.filter { $0.envelope == envelope }
            .sorted { $0.date > $1.date }
    }

    func handleDismiss() {
        dismiss()
    }
    
    var body: some View {
        NavigationView{
            ScrollView {
                VStack(spacing: 20) {
                    // 봉투 정보 섹션
                    VStack(spacing: 16) {
                        // 시작 잔액
                        InfoRow(title: "시작 잔액", value: envelope.budget.formattedCurrency)
                        
                        // 목표 잔액
                        if envelope.goal > 0 {
                            InfoRow(title: "목표 잔액", value: envelope.goal.formattedCurrency)
                        }
                        
                        // 현재 잔액
                        InfoRow(title: "현재 잔액", value: envelope.remaining.formattedCurrency)
                        
                        // 지출 금액
                        InfoRow(title: "지출 금액", value: envelope.spent.formattedCurrency)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    
                    // 거래 내역 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        Text("거래 내역")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                        
                        if filteredTransactions.isEmpty {
                            Text("거래 내역이 없습니다.")
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        } else {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(
                                    transaction: transaction,
                                    onClickMenu: {
                                        selectedTransaction = transaction
                                    }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle(envelope.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: BackButton(onDismiss: handleDismiss),
                trailing: EditButton(action: {
                    showingEditSheet = true
                })
            )
            .sheet(item: $selectedTransaction) { transaction in
                EditTransactionView(transaction: transaction, targetEnvelope: envelope)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showingEditSheet) {
                EditEnvelopeView(shouldDismiss: $shouldDismiss, envelope: envelope)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
            .onChange(of: shouldDismiss) { newValue in
                if newValue {
                    dismiss()
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    let envelope = Envelope(name: "생활비", budget: 1000000, spent: 300000, goal: 2000000)
    return DetailEnvelopeView(envelope: envelope)
}
