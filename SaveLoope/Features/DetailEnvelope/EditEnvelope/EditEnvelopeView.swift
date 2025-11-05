import SwiftUI
import SwiftData

struct EditEnvelopeView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.presentationMode) var presentationMode
    @Binding var shouldDismiss: Bool
    @Bindable var envelope: Envelope
    
    @State private var envelopeName: String = ""
    @State private var initialAmount: Int? = nil
    @State private var goalAmount: Int? = nil
    @State private var isRecurring: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingDeleteAlert: Bool = false
    
    func handleDismiss() {
        dismiss()
    }
    
    func handleEditEnvelope() {
        // 입력값 검증
        if envelopeName.isEmpty {
            alertMessage = "봉투 이름을 입력해주세요"
            showingAlert = true
            return
        }
        
        guard let amount: Int = initialAmount, amount > 0 else {
            alertMessage = "올바른 시작 잔액을 입력해주세요"
            showingAlert = true
            return
        }
        
        // 현재 월에 같은 이름의 봉투가 있는지 확인 (자기 자신 제외)
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        let currentYear: Int = calendar.component(.year, from: currentDate)
        let currentMonth: Int = calendar.component(.month, from: currentDate)
        
        let descriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try modelContext.fetch(descriptor)
            let existingEnvelope = allEnvelopes.first { existingEnvelope in
                existingEnvelope.id != envelope.id &&
                existingEnvelope.name == envelopeName &&
                calendar.component(.year, from: existingEnvelope.createdAt) == currentYear &&
                calendar.component(.month, from: existingEnvelope.createdAt) == currentMonth
            }
            
            if existingEnvelope != nil {
                alertMessage = "이미 같은 이름의 봉투가 존재합니다"
                showingAlert = true
                return
            }
            
            // 봉투 정보 업데이트
            envelope.name = envelopeName
            envelope.budget = amount
            envelope.goal = goalAmount ?? 0
            envelope.isRecurring = isRecurring
            
            // 반복 생성이 필요한 경우 parentId 설정
            if isRecurring {
                envelope.parentId = envelope.id
            } else {
                envelope.parentId = nil
            }
            
            handleDismiss()
        } catch {
            alertMessage = "봉투 수정 중 오류가 발생했습니다"
            showingAlert = true
        }
    }
    
    func handleDeleteEnvelope() {
        // 해당 봉투의 모든 거래 내역 삭제
        let descriptor = FetchDescriptor<TransactionRecord>()
        do {
            let allTransactions = try modelContext.fetch(descriptor)
            let envelopeTransactions = allTransactions.filter { $0.envelope?.id == envelope.id }
            
            for transaction in envelopeTransactions {
                modelContext.delete(transaction)
            }
            
            // 봉투 삭제
            modelContext.delete(envelope)
            
            // 네비게이션 스택을 초기화하여 홈 화면으로 돌아가기
            shouldDismiss = true
            presentationMode.wrappedValue.dismiss()
        } catch {
            alertMessage = "봉투 삭제 중 오류가 발생했습니다"
            showingAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 16) {
                    LabeledTextField(label: "봉투 이름", text: $envelopeName, required: true)
                    LabeledNumberField(label: "시작 잔액", value: $initialAmount, placeholder: "0", required: true, prefix: "원")
                    LabeledNumberField(label: "목표 잔액", value: $goalAmount, placeholder: "0", prefix: "원")
                    
                    Toggle("매달 반복해서 생성", isOn: $isRecurring)
                        .padding(.vertical, 8)
                        .tint(.blue)
                }
                .padding(.horizontal)
                
                Spacer()
                
                HStack(spacing: 20) {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Text("삭제")
                            .font(.system(size: 20, weight: .light))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .background(Color(red: 0.95, green: 0.3, blue: 0.3))
                    .cornerRadius(8)
                    
                    Button(action: handleEditEnvelope) {
                        Text("수정 완료")
                            .font(.system(size: 20, weight: .light))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .background(Color(red: 0.3, green: 0.5, blue: 0.95))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
            }
            .alert("알림", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("봉투 삭제", isPresented: $showingDeleteAlert) {
                Button("취소", role: .cancel) { }
                Button("삭제", role: .destructive) {
                    handleDeleteEnvelope()
                }
            } message: {
                Text("봉투와 관련된 모든 거래 내역이 삭제됩니다. 정말 삭제하시겠습니까?")
            }
            .padding()
            .background(Color.white)
            .navigationTitle("봉투 수정")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: CloseButton(onDismiss: handleDismiss))
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                // 초기값 설정
                envelopeName = envelope.name
                initialAmount = envelope.budget
                goalAmount = envelope.goal
                isRecurring = envelope.isRecurring
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Envelope.self, TransactionRecord.self, configurations: config)
    
    let envelope = Envelope(name: "테스트", budget: 100000, isRecurring: false)
    
    EditEnvelopeView(shouldDismiss: .constant(false), envelope: envelope)
        .modelContainer(container)
}
