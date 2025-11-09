import SwiftUI
import SwiftData

struct EditEnvelopeView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @Environment(\.modelContext) private var modelContext: ModelContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Binding var shouldDismiss: Bool
    @Bindable var envelope: Envelope

    @State private var envelopeName: String = ""
    @State private var initialAmount: Int? = nil
    @State private var goalAmount: Int? = nil
    @State private var selectedEnvelopeType: EnvelopeType = .normal
    @State private var originalEnvelopeType: EnvelopeType = .normal
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingDeleteAlert: Bool = false
    @State private var showingTypeChangeWarning: Bool = false
    @State private var showingPersistentChangeWarning: Bool = false
    @State private var showingSubscription: Bool = false
    @State private var pendingEnvelopeType: EnvelopeType?
    
    var envelopeTypeDescription: String {
        // 지속형 봉투는 타입 변경 불가 안내
        if originalEnvelopeType == .persistent {
            return "지속형 봉투는 타입을 변경할 수 없습니다.\n타입을 변경하려면 삭제 후 새로 생성해주세요."
        }

        switch selectedEnvelopeType {
        case .normal:
            return "현재 월에만 적용되는 봉투입니다.\n다음 달에는 자동으로 사라집니다."
        case .recurring:
            return "매월 초 동일한 조건으로 자동 생성됩니다.\n잔액과 거래내역은 매월 초기화됩니다."
        case .persistent:
            return "삭제하기 전까지 계속 유지됩니다.\n잔액과 거래내역이 초기화되지 않습니다."
        }
    }

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

        // 지속형 봉투 타입 변경 차단 (최종 검증)
        if originalEnvelopeType == .persistent && selectedEnvelopeType != .persistent {
            alertMessage = "지속형 봉투는 타입을 변경할 수 없습니다.\n타입을 변경하려면 삭제 후 새로 생성해주세요."
            showingAlert = true
            return
        }

        // 지속형으로 변경 차단 (최종 검증)
        if originalEnvelopeType != .persistent && selectedEnvelopeType == .persistent {
            alertMessage = "지속형 봉투는 수정으로 변경할 수 없습니다.\n지속형 봉투가 필요하면 새로 생성해주세요."
            showingAlert = true
            return
        }

        // 지속형 봉투는 프리미엄 전용
        if selectedEnvelopeType == .persistent && !subscriptionManager.isSubscribed {
            alertMessage = "지속형 봉투는 프리미엄 기능입니다.\n프리미엄 플랜을 구독하시면 사용할 수 있습니다."
            showingAlert = true
            return
        }

        // 중복 이름 체크 (자기 자신 제외)
        let calendar = Calendar.current
        let currentDate = Date()
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)

        let descriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try modelContext.fetch(descriptor)

            // 지속형 봉투의 경우 전체 데이터베이스에서 이름 중복 체크
            if selectedEnvelopeType == .persistent {
                let existingPersistent = allEnvelopes.first { existingEnvelope in
                    existingEnvelope.id != envelope.id &&
                    existingEnvelope.name == envelopeName &&
                    existingEnvelope.type == .persistent
                }

                if existingPersistent != nil {
                    alertMessage = "이미 같은 이름의 지속형 봉투가 존재합니다"
                    showingAlert = true
                    return
                }
            } else {
                // 일반/반복 봉투는 현재 월에서만 체크 (지속형은 제외)
                let existingEnvelope = allEnvelopes.first { existingEnvelope in
                    existingEnvelope.id != envelope.id &&
                    existingEnvelope.name == envelopeName &&
                    existingEnvelope.type != .persistent &&
                    calendar.component(.year, from: existingEnvelope.createdAt) == currentYear &&
                    calendar.component(.month, from: existingEnvelope.createdAt) == currentMonth
                }

                if existingEnvelope != nil {
                    alertMessage = "이미 같은 이름의 봉투가 현재 월에 존재합니다"
                    showingAlert = true
                    return
                }
            }
            
            // 봉투 정보 업데이트
            envelope.name = envelopeName
            envelope.budget = amount
            envelope.goal = goalAmount ?? 0
            envelope.type = selectedEnvelopeType

            // 반복 생성이 필요한 경우 parentId를 자기 자신으로 설정
            if selectedEnvelopeType == .recurring {
                if envelope.parentId == nil {
                    envelope.parentId = envelope.id
                }
            } else {
                // 반복이 아닌 경우 parentId 제거
                envelope.parentId = nil
            }
            
            // 명시적으로 저장 (아이클라우드 동기화 포함)
            try modelContext.save()
            print("✅ 봉투 수정 저장 완료 (아이클라우드 동기화 시작)")
            
            handleDismiss()
        } catch {
            print("❌ 봉투 수정 저장 실패: \(error.localizedDescription)")
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
            
            // 명시적으로 저장 (아이클라우드 동기화 포함)
            try modelContext.save()
            print("✅ 봉투 삭제 완료 (아이클라우드 동기화 시작)")
            
            // 네비게이션 스택을 초기화하여 홈 화면으로 돌아가기
            shouldDismiss = true
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("❌ 봉투 삭제 실패: \(error.localizedDescription)")
            alertMessage = "봉투 삭제 중 오류가 발생했습니다"
            showingAlert = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(spacing: 16) {
                    LabeledTextField(label: "봉투 이름", text: $envelopeName, required: true)
                    LabeledNumberField(label: "시작 잔액", value: $initialAmount, placeholder: "0", required: true, prefix: CurrencyManager.shared.currentSymbol)
                    LabeledNumberField(label: "목표 잔액", value: $goalAmount, placeholder: "0", prefix: CurrencyManager.shared.currentSymbol)

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("봉투 타입")
                                .font(.system(size: 16, weight: .medium))
                            Text("*")
                                .foregroundColor(.red)
                        }

                        Picker("봉투 타입", selection: $selectedEnvelopeType) {
                            Text("일반 봉투").tag(EnvelopeType.normal)
                            Text("반복 봉투").tag(EnvelopeType.recurring)
                            Text(subscriptionManager.isSubscribed ? "지속 봉투" : "지속 봉투 ⭐️").tag(EnvelopeType.persistent)
                        }
                        .pickerStyle(.segmented)
                        .disabled(originalEnvelopeType == .persistent)
                        .opacity(originalEnvelopeType == .persistent ? 0.5 : 1.0)

                        // 선택된 타입에 대한 설명
                        Text(envelopeTypeDescription)
                            .font(.caption)
                            .foregroundColor(originalEnvelopeType == .persistent ? .orange : .gray)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
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
                if alertMessage.contains("프리미엄") {
                    Button("프리미엄 보기") {
                        showingSubscription = true
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
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
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onChange(of: selectedEnvelopeType) { oldValue, newValue in
                // 지속형 봉투는 타입 변경 완전 차단 (UI에서 비활성화되어 있지만 방어 코드)
                if originalEnvelopeType == .persistent && newValue != .persistent {
                    selectedEnvelopeType = .persistent
                    return
                }

                // 지속형으로 변경 시도 차단
                if originalEnvelopeType != .persistent && newValue == .persistent {
                    showingPersistentChangeWarning = true
                    selectedEnvelopeType = oldValue
                    return
                }

                // 반복 봉투 → 다른 타입 변경 시 경고 (pendingEnvelopeType이 nil일 때만 체크)
                if pendingEnvelopeType == nil && oldValue != newValue && originalEnvelopeType != newValue {
                    if originalEnvelopeType == .recurring && newValue != .recurring {
                        pendingEnvelopeType = newValue
                        showingTypeChangeWarning = true
                        // 일단 원래 값으로 되돌림 (사용자가 확인하기 전까지)
                        selectedEnvelopeType = oldValue
                    }
                }
            }
            .alert("봉투 타입 변경", isPresented: $showingTypeChangeWarning) {
                Button("취소", role: .cancel) {
                    selectedEnvelopeType = originalEnvelopeType
                    pendingEnvelopeType = nil
                }
                Button("변경", role: .destructive) {
                    if let pending = pendingEnvelopeType {
                        // originalEnvelopeType을 업데이트하여 다시 체크되지 않도록 함
                        originalEnvelopeType = pending
                        selectedEnvelopeType = pending
                        pendingEnvelopeType = nil
                    }
                }
            } message: {
                return Text("반복 봉투를 다른 타입으로 변경하면 다음 달부터 자동 생성되지 않습니다.")
            }
            .alert("지속형 봉투 변경 불가", isPresented: $showingPersistentChangeWarning) {
                Button("확인", role: .cancel) {
                    selectedEnvelopeType = originalEnvelopeType
                }
            } message: {
                Text("지속형 봉투는 수정으로 변경할 수 없습니다.\n지속형 봉투가 필요하면 새로 생성해주세요.")
            }
            .onAppear {
                // 초기값 설정
                envelopeName = envelope.name
                initialAmount = envelope.budget
                goalAmount = envelope.goal
                selectedEnvelopeType = envelope.type
                originalEnvelopeType = envelope.type
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Envelope.self, TransactionRecord.self, configurations: config)
        
        let envelope = Envelope(name: "테스트", budget: 100000, isRecurring: false)
        
        return EditEnvelopeView(shouldDismiss: .constant(false), envelope: envelope)
            .modelContainer(container)
    } catch {
        return Text("Preview 설정 실패: \(error.localizedDescription)")
    }
}
