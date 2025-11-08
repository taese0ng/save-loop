import SwiftUI
import SwiftData

struct AddBalanceView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query private var envelopes: [Envelope]
    @Query(sort: \TransactionRecord.date) private var allTransactions: [TransactionRecord]

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedEnvelope: Envelope?
    @State private var amount: Int?
    @State private var date: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var alertTitle: String = "알림"
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var showingSubscription = false
    @EnvironmentObject private var dateSelection: DateSelectionState

    private var filteredEnvelopes: [Envelope] {
        let calendar: Calendar = Calendar.current
        return envelopes.filter { envelope in
            // 지속형 봉투는 항상 포함
            if envelope.type == .persistent {
                return true
            }

            // 일반/반복 봉투는 선택된 월과 일치하는 것만
            return calendar.component(.year, from: envelope.createdAt) == calendar.component(.year, from: dateSelection.selectedDate) &&
                   calendar.component(.month, from: envelope.createdAt) == calendar.component(.month, from: dateSelection.selectedDate)
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
    

    func handleAddBalance() {
        // 입력값 검증
        guard let envelope = selectedEnvelope else {
            alertTitle = "알림"
            alertMessage = "봉투를 선택해주세요"
            showingAlert = true
            return
        }

        // 금액 검증
        guard let amountInt: Int = amount, amountInt > 0 else {
            alertTitle = "알림"
            alertMessage = "올바른 금액을 입력해주세요"
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
            alertTitle = "제한 도달"
            alertMessage = PremiumFeatureManager.shared.getTransactionLimitMessage()
            showingAlert = true
            showingSubscription = true
            return
        }
        
        // TransactionRecord 생성 및 저장
        let newRecord = TransactionRecord(
            amount: amountInt, 
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
        envelope.income += amountInt
        
        // 명시적으로 저장 (아이클라우드 동기화 포함)
        do {
            try modelContext.save()
            print("✅ 잔액 추가 저장 완료 (아이클라우드 동기화 시작)")
            // 성공적으로 저장되면 화면 닫기
            handleDismiss()
        } catch {
            print("❌ 잔액 추가 저장 실패: \(error.localizedDescription)")
            // 롤백: 변경사항 되돌리기
            envelope.income -= amountInt
            alertMessage = "잔액 추가 중 오류가 발생했습니다"
            showingAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack(alignment: .leading, spacing: 20) {
                    
                    RadioButtonGroup(
                        title: "잔액추가 봉투",
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
                        label: "추가 금액",
                        value: $amount,
                        placeholder: "0",
                        required: true,
                        prefix: "원"
                    )

                    DatePickerButton(
                        label: "추가 날짜",
                        date: $date,
                        showingDatePicker: $showingDatePicker,
                        selectedDate: dateSelection.selectedDate
                    )

                    NoteTextField(
                        label: "설명",
                        text: $note,
                        placeholder: "설명"
                    )

                    if let envelope = selectedEnvelope, envelope.isRecurring {
                        RecurringToggle(
                            label: "매달 반복해서 생성",
                            isOn: $isRecurring
                        )
                    }

                    Spacer()

                    SubmitButton(
                        title: "잔액 추가",
                        action: handleAddBalance
                    )
                    
                }
                .padding()
            }
            .background(Color.white)
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationTitle("잔액추가")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
                if showingSubscription {
                    Button("프리미엄 보기") {
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
    }
}


struct AddBalanceView_Previews: PreviewProvider {
    static var previews: some View {
        AddBalanceView()
    }
}
