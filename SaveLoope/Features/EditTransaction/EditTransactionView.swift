import SwiftUI
import SwiftData

struct EditTransactionView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Query(sort: \Envelope.name) private var envelopes: [Envelope]
    
    let transaction: TransactionRecord
    
    @State private var selectedEnvelope: Envelope?
    @State private var amount: Int?
    @State private var date: Date = Date()
    @State private var showingDatePicker: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var note: String = ""
    @State private var transactionType: TransactionType = .expense
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
    
    func handleEditTransaction() {
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
        
        // 원래 봉투의 spent/income 값 업데이트
        if transaction.type == .expense {
            transaction.envelope?.spent -= transaction.amount
        } else {
            transaction.envelope?.income -= transaction.amount
        }
        
        // 새로운 봉투의 spent/income 값 업데이트
        if transactionType == .expense {
            envelope.spent += amountInt
        } else {
            envelope.income += amountInt
        }
        
        // 트랜잭션 정보 업데이트
        transaction.amount = amountInt
        transaction.date = date
        transaction.envelope = envelope
        transaction.note = note
        transaction.type = transactionType
        transaction.isRecurring = isRecurring
        
        if isRecurring {
            transaction.parentId = transaction.id
        } else {
            transaction.parentId = nil
        }
        
        // 성공적으로 저장되면 화면 닫기
        handleDismiss()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RadioButtonGroup(
                        title: "봉투 선택",
                        items: filteredEnvelopes,
                        selectedItem: selectedEnvelope,
                        isRecurring: { $0.isRecurring },
                        itemTitle: { $0.name },
                        onSelection: { envelope in
                            selectedEnvelope = envelope
                            // 반복 생성 봉투가 아닌 경우 토글 비활성화
                            if !envelope.isRecurring {
                                isRecurring = false
                            }
                        }
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("거래 유형")
                            .font(.system(size: 16))
                        Picker("거래 유형", selection: $transactionType) {
                            Text("지출").tag(TransactionType.expense)
                            Text("수입").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    LabeledNumberField(
                        label: "금액",
                        value: $amount,
                        placeholder: "0",
                        required: true,
                        prefix: "원"
                    )
                    
                    Text("날짜")
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
                        MonthCalendarView(selectedDate: dateSelection.selectedDate, date: $date)
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
                    
                    if selectedEnvelope?.isRecurring == true {
                        Toggle("매달 반복해서 생성", isOn: $isRecurring)
                            .padding(.vertical, 8)
                            .tint(.blue)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(action: handleEditTransaction) {
                            Text("수정 완료")
                                .font(.system(size: 20, weight: .light))
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
            .navigationTitle("거래 수정")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: CloseButton(onDismiss: handleDismiss))
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("알림", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
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
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Envelope.self, TransactionRecord.self, configurations: config)
    
    let envelope = Envelope(name: "테스트", budget: 100000, isRecurring: false)
    let transaction = TransactionRecord(amount: 10000, date: Date(), type: .expense, envelope: envelope, note: "테스트", isRecurring: false)
    
    return EditTransactionView(transaction: transaction)
        .modelContainer(container)
        .environmentObject(DateSelectionState())
}
