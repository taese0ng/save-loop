import SwiftUI
import SwiftData

struct AddExpenseView: View {
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
   @State private var alertTitle: String = "알림"
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
   
   func handleAddExpense() {
       // 입력값 검증
       guard let envelope = selectedEnvelope else {
           alertTitle = "알림"
           alertMessage = "봉투를 선택해주세요"
           showingAlert = true
           return
       }

       // 금액 검증
       guard let amountValue = amount, amountValue > 0 else {
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
       
       // 지출 기록 생성 및 저장
       let newRecord = TransactionRecord(
           amount: amountValue,
           date: date,
           type: .expense,
           envelope: envelope,
           note: note,
           isRecurring: isRecurring
       )

       // 반복 거래인 경우 parentId를 자기 자신으로 설정
       if isRecurring {
           newRecord.parentId = newRecord.id
       }

       modelContext.insert(newRecord)

       // 선택된 봉투의 spent 업데이트
       envelope.spent += amountValue
       
       // 명시적으로 저장 (아이클라우드 동기화 포함)
       do {
           try modelContext.save()
           print("✅ 지출 등록 저장 완료 (아이클라우드 동기화 시작)")
           // 성공적으로 저장되면 화면 닫기
           handleDismiss()
       } catch {
           print("❌ 지출 등록 저장 실패: \(error.localizedDescription)")
           // 롤백: 변경사항 되돌리기
           envelope.spent -= amountValue
           alertMessage = "지출 등록 중 오류가 발생했습니다"
           showingAlert = true
       }
   }
   
  var body: some View {
      NavigationView {
          ScrollView {
              VStack(alignment: .leading, spacing: 20) {
                  RadioButtonGroup(
                      title: "지출 봉투",
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
                      label: "지출 금액",
                      value: $amount,
                      placeholder: "0",
                      required: true,
                      prefix: CurrencyManager.shared.currentSymbol
                  )

                  DatePickerButton(
                      label: "지출 날짜",
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
                      title: "지출 등록",
                      action: handleAddExpense
                  )
              }
              .padding()
          }
          .background(Color("Background"))
          .navigationTitle("지출등록")
          .navigationBarTitleDisplayMode(.inline)
          .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))
          .toolbarBackground(Color("Background"), for: .navigationBar)
          .toolbarBackground(.visible, for: .navigationBar)
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
      .navigationViewStyle(.stack)
  }
}


struct AddExpenseView_Previews: PreviewProvider {
   static var previews: some View {
       AddExpenseView()
   }
}
