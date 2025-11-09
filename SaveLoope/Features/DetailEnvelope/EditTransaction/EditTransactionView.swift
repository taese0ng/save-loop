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
        let calendar = Calendar.current
        let selectedDate = dateSelection.selectedDate
        let selectedYear = calendar.component(.year, from: selectedDate)
        let selectedMonth = calendar.component(.month, from: selectedDate)
        
        return envelopes.filter { envelope in
            // 지속형 봉투는 항상 포함
            if envelope.type == .persistent {
                return true
            }

            // 일반/반복 봉투는 선택된 월과 일치하는 것만
            return calendar.component(.year, from: envelope.createdAt) == selectedYear &&
                   calendar.component(.month, from: envelope.createdAt) == selectedMonth
        }
        .sorted { env1, env2 in
            // sortOrder가 0이면 Int.max로 취급 (맨 뒤로)
            let order1 = env1.sortOrder == 0 ? Int.max : env1.sortOrder
            let order2 = env2.sortOrder == 0 ? Int.max : env2.sortOrder

            if order1 != order2 {
                return order1 < order2
            }

            // sortOrder가 같으면 날짜 기준 정렬
            let date1 = getSortDate(for: env1)
            let date2 = getSortDate(for: env2)
            return date1 < date2
        }
    }

    // 정렬용 날짜 반환: 반복 봉투는 원본(parent)의 createdAt 사용
    private func getSortDate(for envelope: Envelope) -> Date {
        // 반복 봉투이고 parentId가 있는 경우
        if envelope.type == .recurring, let parentId = envelope.parentId {
            // 원본 봉투 찾기
            if let parent = envelopes.first(where: { $0.id == parentId && $0.parentId == $0.id }) {
                return parent.createdAt
            }
        }
        // 그 외의 경우 자신의 createdAt 사용
        return envelope.createdAt
    }

    private let numberFormatter: NumberFormatter = {
        let formatter: NumberFormatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter
    }()
    
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
        NavigationView {
            VStack(spacing: 0) {
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
                .background(Color.white)

                ActionButtons(
                    deleteTitle: "삭제",
                    confirmTitle: "수정 완료",
                    onDelete: { showingDeleteAlert = true },
                    onConfirm: handleEditTransaction
                )
            }
            .navigationTitle("거래 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
        .navigationViewStyle(.stack)
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
