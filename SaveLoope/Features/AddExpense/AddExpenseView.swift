import SwiftUI
import SwiftData

struct AddExpenseView: View {
   @Environment(\.dismiss) private var dismiss: DismissAction
   @Environment(\.modelContext) private var modelContext: ModelContext
   @Query(sort: \Envelope.name) private var envelopes: [Envelope]
   
   @State private var selectedEnvelope: Envelope?
   @State private var amount: Int?
   @State private var date: Date = Date()
   @State private var showingDatePicker: Bool = false
   @State private var showingAlert: Bool = false
   @State private var alertMessage: String = ""
   @State private var note: String = ""
   @State private var isRecurring: Bool = false
   @EnvironmentObject private var dateSelection: DateSelectionState

    private var filteredEnvelopes: [Envelope] {
        let calendar: Calendar = Calendar.current
        return envelopes.filter { envelope in
            calendar.component(.year, from: envelope.createdAt) == calendar.component(.year, from: dateSelection.selectedDate) &&
            calendar.component(.month, from: envelope.createdAt) == calendar.component(.month, from: dateSelection.selectedDate)
        }
    }
   
   private let dateFormatter: DateFormatter = {
       let formatter: DateFormatter = DateFormatter()
       formatter.dateFormat = "yyyy.MM.dd"
       formatter.locale = Locale(identifier: "ko_KR")
       return formatter
   }()
   
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
   
   func handleAddExpense() {
       // 입력값 검증
       guard let envelope = selectedEnvelope else {
           alertMessage = "봉투를 선택해주세요"
           showingAlert = true
           return
       }
       
       // 금액 검증
       guard let amountInt = amount, amountInt > 0 else {
           alertMessage = "올바른 금액을 입력해주세요"
           showingAlert = true
           return
       }
       
       // 지출 기록 생성 및 저장
       let newRecord = TransactionRecord(amount: amountInt, date: date, type: .expense, envelope: envelope, note: note, isRecurring: isRecurring)
       
       if isRecurring {
            newRecord.parentId = newRecord.id
        }

       modelContext.insert(newRecord)
       
       // 선택된 봉투의 spent 업데이트
       envelope.spent += amountInt
       
       // 성공적으로 저장되면 화면 닫기
       handleDismiss()
   }
   
   var body: some View {
       NavigationView {
           ScrollView {
               VStack(alignment: .leading, spacing: 20) {
                   RadioButtonGroup(
                       title: "지출 봉투",
                       items: filteredEnvelopes,
                       selectedItem: selectedEnvelope,
                       isRecurring: { $0.isRecurring },
                       itemTitle: { $0.name },
                       onSelection: { envelope in
                           selectedEnvelope = envelope
                       }
                   )
                   
                   LabeledNumberField(
                       label: "지출 금액",
                       value: $amount,
                       placeholder: "0",
                       required: true,
                       prefix: "원"
                   )
                   
                   Text("지출 날짜")
                       .font(.system(size: 16))
                   Button(action: {
                       showingDatePicker = true
                   }) {
                       HStack {
                           Text(dateFormatter.string(from: date))
                               .foregroundColor(.black)
                           Spacer()
                           Image(systemName: "calendar")
                               .foregroundColor(.gray)
                       }
                       .frame(maxWidth: .infinity, alignment: .leading)
                       .padding(.horizontal, 8)
                       .padding(.vertical, 8)
                       .background(Color(.systemBackground))
                       .cornerRadius(5)
                       .overlay(
                           RoundedRectangle(cornerRadius: 5)
                               .stroke(Color(.systemGray4), lineWidth: 1)
                       )
                   }
                   .buttonStyle(PlainButtonStyle())
                   .sheet(isPresented: $showingDatePicker) {
                       DatePicker("",
                                selection: $date,
                                displayedComponents: .date)
                           .datePickerStyle(.graphical)
                           .environment(\.locale, Locale(identifier: "ko_KR"))
                           .environment(\.calendar, Calendar(identifier: .gregorian))
                           .padding()
                           .presentationDetents([.height(400)])
                           .presentationDragIndicator(.visible)
                           .onChange(of: date) { oldValue, newValue in
                               showingDatePicker = false
                           }
                   }
                   
                   Text("설명")
                       .font(.system(size: 16))
                   TextField("설명", text: $note)
                       .padding(.horizontal, 8)
                       .padding(.vertical, 8)
                       .background(Color(.systemBackground))
                       .cornerRadius(5)
                       .overlay(
                           RoundedRectangle(cornerRadius: 5)
                               .stroke(Color(.systemGray4), lineWidth: 1)
                       )

                   if (selectedEnvelope != nil && selectedEnvelope!.isRecurring) {
                       Toggle("매달 반복해서 생성", isOn: $isRecurring)
                           .padding(.vertical, 8)
                   }
                   
                   Spacer()
                   
                   HStack{
                       Spacer()
                       Button(action: handleAddExpense) {
                           Text("지출 등록")
                               .font(.system(size:20, weight: .light))
                               .fontWeight(.bold)
                               .foregroundColor(.white)
                       }
                       .padding(.vertical, 12)
                       .padding(.horizontal, 32)
                       .background(Color.blue)
                       .cornerRadius(8)
                       Spacer()
                   }

               }
               .padding()
            }
           .navigationTitle("지출등록")
           .navigationBarTitleDisplayMode(.inline)
           .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))
           .toolbarBackground(Color(.systemBackground), for: .navigationBar)
           .toolbarBackground(.visible, for: .navigationBar)
           .alert("알림", isPresented: $showingAlert) {
               Button("확인", role: .cancel) { }
           } message: {
               Text(alertMessage)
           }
           .onAppear {
               if !filteredEnvelopes.isEmpty {
                   selectedEnvelope = filteredEnvelopes[0]
               }
           }
       }
   }
}


struct AddExpenseView_Previews: PreviewProvider {
   static var previews: some View {
       AddExpenseView()
   }
}
