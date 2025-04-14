import SwiftUI
import SwiftData

struct AddEnvelopeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss: DismissAction     
    @State private var envelopeName: String = ""
    @State private var initialAmount: Int? = nil
    @State private var goalAmount: Int? = nil
    @State private var isRecurring: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    
    func handleDismiss() {
        dismiss()
    }
    
    func handleAddEnvelope() {
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
        
        // 현재 월에 같은 이름의 봉투가 있는지 확인
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        let currentYear: Int = calendar.component(.year, from: currentDate)
        let currentMonth: Int = calendar.component(.month, from: currentDate)
        
        let descriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try modelContext.fetch(descriptor)
            let existingEnvelope = allEnvelopes.first { envelope in
                envelope.name == envelopeName &&
                calendar.component(.year, from: envelope.createdAt) == currentYear &&
                calendar.component(.month, from: envelope.createdAt) == currentMonth
            }
            
            if existingEnvelope != nil {
                alertMessage = "이미 같은 이름의 봉투가 존재합니다"
                showingAlert = true
                return
            }
            
            let newEnvelope = Envelope(
                name: envelopeName,
                budget: amount,
                income: 0,
                spent: 0,
                goal: (goalAmount ?? 0),
                isRecurring: isRecurring
            )
            
            // 반복 생성이 필요한 경우 parentId 설정
            if isRecurring {
                newEnvelope.parentId = newEnvelope.id
            }
            
            modelContext.insert(newEnvelope)
            handleDismiss()
        } catch {
            alertMessage = "봉투 생성 중 오류가 발생했습니다"
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
                }
                .padding(.horizontal)

                Spacer()

                HStack{
                    Spacer()
                    AddEnvelopeButton(action: handleAddEnvelope)
                    Spacer()
                }
            }
            .alert("알림", isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .padding()
            .navigationTitle("봉투 추가")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))           
            .toolbarBackground(Color(.systemBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    AddEnvelopeView()
}
