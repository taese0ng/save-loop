import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query private var envelopes: [Envelope]
    
    let transaction: TransactionRecord
    let targetEnvelope: Envelope
    
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var selectedEnvelope: Envelope?
    @State private var amount: Double?
    @State private var date: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var showingAlert: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var note: String = ""
    @State private var transactionType: TransactionType = .expense
    @State private var isRecurring: Bool = false
    @EnvironmentObject private var dateSelection: DateSelectionState

    private var filteredEnvelopes: [Envelope] {
        EnvelopeUtils.filterAndSortEnvelopes(envelopes, selectedDate: dateSelection.selectedDate)
    }
    
    func handleDismiss() {
        dismiss()
    }
    
    func handleEditTransaction() {
        // 입력값 검증
        guard let envelope = selectedEnvelope else {
            alertMessage = "봉투를 선택해주세요"
            showingAlert = true
            return
        }
        
        // 금액 검증
        guard let amountValue = amount, amountValue > 0 else {
            alertMessage = "올바른 금액을 입력해주세요"
            showingAlert = true
            return
        }
        
        // 원래 봉투의 spent/income 값 복원 (기존 금액 되돌리기)
        if let oldEnvelope = transaction.envelope {
            if transaction.type == .expense {
                oldEnvelope.spent -= transaction.amount
            } else {
                oldEnvelope.income -= transaction.amount
            }
        }
        
        // 새로운 봉투에 새 금액과 타입 적용
        if transactionType == .expense {
            envelope.spent += amountValue
        } else {
            envelope.income += amountValue
        }
        
        // 트랜잭션 정보 업데이트
        transaction.amount = amountValue
        transaction.date = date
        transaction.envelope = envelope
        transaction.note = note
        transaction.type = transactionType
        transaction.isRecurring = isRecurring
        
        if isRecurring {
            // 반복 거래인 경우: parentId가 없으면 자기 자신을 parent로 설정
            if transaction.parentId == nil {
                transaction.parentId = transaction.id
            }
        } else {
            // 반복이 아닌 경우: parentId 제거
            transaction.parentId = nil
        }
        
        // 명시적으로 저장 (아이클라우드 동기화 포함)
        do {
            try modelContext.save()
            print("✅ 거래 수정 저장 완료 (아이클라우드 동기화 시작)")
            // 성공적으로 저장되면 화면 닫기
            handleDismiss()
        } catch {
            print("❌ 거래 수정 저장 실패: \(error.localizedDescription)")
            alertMessage = "거래 수정 중 오류가 발생했습니다"
            showingAlert = true
        }
    }
    
    func handleDeleteTransaction() {
        // 거래 내역 삭제 전에 봉투 잔액 업데이트
        if transaction.type == .expense {
            // 지출 취소: currentBudget 증가
            targetEnvelope.spent -= transaction.amount
        } else if transaction.type == .income {
            // 수입 취소: currentBudget 감소
            targetEnvelope.income -= transaction.amount
        }
        
        // 거래 내역 삭제
        modelContext.delete(transaction)
        
        // 명시적으로 저장 (아이클라우드 동기화 포함)
        do {
            try modelContext.save()
            print("✅ 거래 삭제 완료 (아이클라우드 동기화 시작)")
            handleDismiss()
        } catch {
            print("❌ 거래 삭제 실패: \(error.localizedDescription)")
            // 롤백
            if transaction.type == .expense {
                targetEnvelope.spent += transaction.amount
            } else if transaction.type == .income {
                targetEnvelope.income += transaction.amount
            }
        }
    }
    
    var body: some View {
        StandardSheetContainer(title: "거래 수정") {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RadioButtonGroup(
                        title: "봉투 선택",
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

                    TransactionTypePicker(
                        label: "유형",
                        selectedType: $transactionType
                    )

                    LabeledNumberField(
                        label: "금액",
                        value: $amount,
                        placeholder: "0",
                        required: true,
                        prefix: CurrencyManager.shared.currentSymbol
                    )

                    DatePickerButton(
                        label: "날짜",
                        date: $date,
                        showingDatePicker: $showingDatePicker,
                        selectedDate: dateSelection.selectedDate
                    )

                    NoteTextField(
                        label: "설명",
                        text: $note,
                        placeholder: "설명"
                    )

                    if selectedEnvelope?.isRecurring == true {
                        RecurringToggle(
                            label: "매달 반복해서 생성",
                            isOn: $isRecurring
                        )
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
        } footer: {
            ActionButtons(
                deleteTitle: "삭제",
                confirmTitle: "수정 완료",
                onDelete: { showingDeleteAlert = true },
                onConfirm: handleEditTransaction
            )
        }
        .alert("알림", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("거래 삭제", isPresented: $showingDeleteAlert) {
            Button("취소", role: .cancel) { }
            Button("삭제", role: .destructive) {
                handleDeleteTransaction()
            }
        } message: {
            Text("정말로 이 거래를 삭제하시겠습니까?")
        }
        .onAppear {
            // 초기값 설정
            selectedEnvelope = transaction.envelope
            amount = transaction.amount
            date = transaction.date
            note = transaction.note
            transactionType = transaction.type
            isRecurring = transaction.isRecurring
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Envelope.self, TransactionRecord.self, configurations: config)
        
        let envelope = Envelope(name: "테스트", budget: 100000.0, isRecurring: false)
        let transaction = TransactionRecord(amount: 10000.0, date: Date(), type: .expense, envelope: envelope, note: "테스트", isRecurring: false)
        
        return EditTransactionView(transaction: transaction, targetEnvelope: envelope)
            .modelContainer(container)
            .environmentObject(DateSelectionState())
    } catch {
        return Text("Preview 설정 실패: \(error.localizedDescription)")
    }
}
