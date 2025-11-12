import SwiftUI
import SwiftData

struct AddBalanceView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query private var envelopes: [Envelope]
    @Query(sort: \TransactionRecord.date) private var allTransactions: [TransactionRecord]

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedEnvelope: Envelope?
    @State private var amount: Double?
    @State private var date: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = ""
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var showingSubscription = false
    @EnvironmentObject private var dateSelection: DateSelectionState

    private var filteredEnvelopes: [Envelope] {
        EnvelopeUtils.filterAndSortEnvelopes(envelopes, selectedDate: dateSelection.selectedDate)
    }
    
    func handleDismiss() {
        dismiss()
    }
    

    func handleAddBalance() {
        // 입력값 검증
        guard let envelope = selectedEnvelope else {
            alertTitle = "common.alert".localized
            alertMessage = "add_balance.select_envelope".localized
            showingAlert = true
            return
        }

        // 금액 검증
        guard let amountValue = amount, amountValue > 0 else {
            alertTitle = "common.alert".localized
            alertMessage = "add_balance.invalid_amount".localized
            showingAlert = true
            return
        }

        // 프리미엄 기능 체크: 봉투당 거래 내역 개수 제한
        let envelopeTransactionsCount = allTransactions.filter { $0.envelope?.id == envelope.id }.count
        let canAddTransaction = PremiumFeatureManager.shared.canAddMoreTransactions(
            currentCount: envelopeTransactionsCount,
            isSubscribed: subscriptionManager.isSubscribed
        )

        if !canAddTransaction {
            alertTitle = "premium.limit_reached".localized
            alertMessage = PremiumFeatureManager.shared.getTransactionLimitMessage()
            showingAlert = true
            showingSubscription = true
            return
        }
        
        // TransactionRecord 생성 및 저장
        let newRecord = TransactionRecord(
            amount: amountValue,
            date: date,
            type: .income,
            envelope: envelope,
            note: note,
            isRecurring: isRecurring
        )

        // 반복 거래인 경우 parentId를 자기 자신으로 설정
        if isRecurring {
            newRecord.parentId = newRecord.id
        }

        modelContext.insert(newRecord)

        // 수입 추가 시 income 증가
        envelope.income += amountValue
        
        // 명시적으로 저장 (아이클라우드 동기화 포함)
        do {
            try modelContext.save()
            print("✅ 잔액 추가 저장 완료 (아이클라우드 동기화 시작)")
            // 성공적으로 저장되면 화면 닫기
            handleDismiss()
        } catch {
            print("❌ 잔액 추가 저장 실패: \(error.localizedDescription)")
            // 롤백: 변경사항 되돌리기
            envelope.income -= amountValue
            alertMessage = "error.balance_add".localized
            showingAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RadioButtonGroup(
                        title: "add_balance.envelope".localized, // 잔액추가 봉투
                        items: filteredEnvelopes,
                        selectedItem: selectedEnvelope,
                        envelopeType: { $0.type },
                        itemTitle: { $0.name },
                        onSelection: { envelope in
                            selectedEnvelope = envelope
                            if !envelope.isRecurring {
                                isRecurring = false
                            }
                        }
                    )

                    LabeledNumberField(
                        label: "add_balance.amount".localized, // 추가 금액
                        value: $amount,
                        placeholder: "0",
                        required: true,
                        prefix: CurrencyManager.shared.currentSymbol
                    )

                    DatePickerButton(
                        label: "add_balance.date".localized, // 추가 날짜
                        date: $date,
                        showingDatePicker: $showingDatePicker,
                        selectedDate: dateSelection.selectedDate
                    )

                    NoteTextField(
                        label: "transaction.note".localized, // 메모
                        text: $note,
                        placeholder: "transaction.note_placeholder".localized // 설명
                    )

                    if let envelope = selectedEnvelope, envelope.isRecurring {
                        RecurringToggle(
                            label: "transaction.recurring_label".localized, // 매달 반복해서 생성
                            isOn: $isRecurring
                        )
                    }

                    Spacer()

                    SubmitButton(
                        title: "add_balance.button".localized, // 잔액 추가
                        action: handleAddBalance
                    )
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("add_balance.title".localized) // 잔액추가
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("common.ok".localized, role: .cancel) { } // 확인
                if showingSubscription {
                    Button("premium.view".localized) { // 프리미엄 보기
                        // sheet will open automatically
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
            .onAppear {
                if !filteredEnvelopes.isEmpty {
                   selectedEnvelope = filteredEnvelopes[0]
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}


struct AddBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        AddBalanceView()
    }
}
