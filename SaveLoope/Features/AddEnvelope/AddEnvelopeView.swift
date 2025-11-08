import SwiftUI
import SwiftData

struct AddEnvelopeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var envelopeName: String = ""
    @State private var initialAmount: Int? = nil
    @State private var goalAmount: Int? = nil
    @State private var selectedEnvelopeType: EnvelopeType = .normal
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingSubscription: Bool = false
    
    var envelopeTypeDescription: String {
        switch selectedEnvelopeType {
        case .normal:
            return "현재 월에만 적용되는 봉투입니다.\n다음 달에는 자동으로 사라집니다."
        case .recurring:
            return "매월 초 동일한 조건으로 자동 생성됩니다.\n잔액과 거래내역은 매월 초기화됩니다."
        case .persistent:
            return "삭제하기 전까지 계속 유지됩니다.\n잔액과 거래내역이 초기화되지 않습니다.\n\n⚠️ 생성 후에는 타입 변경이 불가능합니다."
        }
    }

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

        // 지속형 봉투는 프리미엄 전용
        if selectedEnvelopeType == .persistent && !subscriptionManager.isSubscribed {
            alertMessage = "지속형 봉투는 프리미엄 기능입니다.\n프리미엄 플랜을 구독하시면 사용할 수 있습니다."
            showingAlert = true
            return
        }
        
        // 중복 이름 체크
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        let currentYear: Int = calendar.component(.year, from: currentDate)
        let currentMonth: Int = calendar.component(.month, from: currentDate)

        let descriptor = FetchDescriptor<Envelope>()
        do {
            let allEnvelopes = try modelContext.fetch(descriptor)

            // 지속형 봉투의 경우 전체 데이터베이스에서 이름 중복 체크
            if selectedEnvelopeType == .persistent {
                let existingPersistent = allEnvelopes.first { envelope in
                    envelope.name == envelopeName &&
                    envelope.type == .persistent
                }

                if existingPersistent != nil {
                    alertMessage = "이미 같은 이름의 지속형 봉투가 존재합니다"
                    showingAlert = true
                    return
                }
            } else {
                // 일반/반복 봉투는 현재 월에서만 체크 (지속형은 제외)
                let existingEnvelope = allEnvelopes.first { envelope in
                    envelope.name == envelopeName &&
                    envelope.type != .persistent &&
                    calendar.component(.year, from: envelope.createdAt) == currentYear &&
                    calendar.component(.month, from: envelope.createdAt) == currentMonth
                }

                if existingEnvelope != nil {
                    alertMessage = "이미 같은 이름의 봉투가 현재 월에 존재합니다"
                    showingAlert = true
                    return
                }
            }
            
            let newEnvelope = Envelope(
                name: envelopeName,
                budget: amount,
                income: 0,
                spent: 0,
                goal: (goalAmount ?? 0),
                isRecurring: selectedEnvelopeType == .recurring,
                envelopeType: selectedEnvelopeType
            )

            // 반복 생성이 필요한 경우 parentId를 자기 자신으로 설정
            if selectedEnvelopeType == .recurring {
                newEnvelope.parentId = newEnvelope.id
            }

            // 마지막 순서로 설정 (최대 sortOrder + 1)
            let maxSortOrder = allEnvelopes.map { $0.sortOrder }.max() ?? 0
            newEnvelope.sortOrder = maxSortOrder + 1

            modelContext.insert(newEnvelope)
            
            // 명시적으로 저장 (아이클라우드 동기화 포함)
            do {
                try modelContext.save()
                print("✅ 봉투 저장 완료 (아이클라우드 동기화 시작)")
                handleDismiss()
            } catch {
                print("❌ 봉투 저장 실패: \(error.localizedDescription)")
                alertMessage = "봉투 저장 중 오류가 발생했습니다"
                showingAlert = true
            }
        } catch {
            alertMessage = "봉투 생성 중 오류가 발생했습니다"
            showingAlert = true
        }
    }

    var body: some View {
         NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(spacing: 16) {
                        LabeledTextField(label: "봉투 이름", text: $envelopeName, required: true)
                        LabeledNumberField(label: "시작 잔액", value: $initialAmount, placeholder: "0", required: true, prefix: "원")
                        LabeledNumberField(label: "목표 잔액", value: $goalAmount, placeholder: "0", prefix: "원")

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

                            // 선택된 타입에 대한 설명
                            Text(envelopeTypeDescription)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                    }

                    Spacer()
                        .frame(height: 40)

                    HStack{
                        Spacer()
                        AddEnvelopeButton(action: handleAddEnvelope)
                        Spacer()
                    }
                }
                .padding()
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
            .background(Color.white)
            .navigationTitle("봉투 추가")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))           
            .toolbarBackground(.white, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

#Preview {
    AddEnvelopeView()
}
