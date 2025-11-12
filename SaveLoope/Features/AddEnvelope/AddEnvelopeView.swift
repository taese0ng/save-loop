import SwiftUI
import SwiftData

struct AddEnvelopeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @State private var envelopeName: String = ""
    @State private var initialAmount: Double? = nil
    @State private var goalAmount: Double? = nil
    @State private var selectedEnvelopeType: EnvelopeType = .normal
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showingSubscription: Bool = false
    
    var envelopeTypeDescription: String {
        switch selectedEnvelopeType {
        case .normal:
            return "envelope.type.description.normal".localized
        case .recurring:
            return "envelope.type.description.recurring".localized
        case .persistent:
            return "envelope.type.description.persistent".localized
        }
    }

    func handleDismiss() {
        dismiss()
    }

    func handleAddEnvelope() {
        // 입력값 검증
        if envelopeName.isEmpty {
            alertMessage = "envelope.name_required".localized
            showingAlert = true
            return
        }

        guard let amount: Double = initialAmount, amount > 0 else {
            alertMessage = "envelope.invalid_budget".localized
            showingAlert = true
            return
        }

        // 지속형 봉투는 프리미엄 전용
        if selectedEnvelopeType == .persistent && !subscriptionManager.isSubscribed {
            alertMessage = "envelope.persistent_premium_required".localized
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
                    alertMessage = "envelope.name_exists".localized
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
                    alertMessage = "envelope.name_exists_current_month".localized
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
                alertMessage = "error.save_failed".localized
                showingAlert = true
            }
        } catch {
            alertMessage = "error.save_failed".localized
            showingAlert = true
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LabeledTextField(label: "envelope.name".localized, text: $envelopeName, required: true) // 봉투 이름
                    LabeledNumberField(label: "envelope.initial_balance".localized, value: $initialAmount, placeholder: "0", required: true, prefix: CurrencyManager.shared.currentSymbol) // 시작 잔액
                    LabeledNumberField(label: "envelope.goal".localized, value: $goalAmount, placeholder: "0", prefix: CurrencyManager.shared.currentSymbol) // 목표 잔액

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("envelope.type") // 봉투 타입
                                .font(.system(size: 16, weight: .medium))
                            Text("*")
                                .foregroundColor(.red)
                        }

                        Picker("envelope.type".localized, selection: $selectedEnvelopeType) { // 봉투 타입
                            Text("envelope.type.normal").tag(EnvelopeType.normal) // 일반 봉투
                            Text("envelope.type.recurring").tag(EnvelopeType.recurring) // 반복 봉투
                            Text(subscriptionManager.isSubscribed ? "envelope.type.persistent" : "envelope.type.persistent".localized + " ⭐️").tag(EnvelopeType.persistent) // 지속 봉투
                        }
                        .pickerStyle(.segmented)

                        // 선택된 타입에 대한 설명
                        Text(envelopeTypeDescription)
                            .font(.caption)
                            .foregroundColor(Color("SecondaryText"))
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)

                    Spacer()
                        .frame(height: 40)

                    HStack {
                        Spacer()
                        AddEnvelopeButton(action: handleAddEnvelope)
                        Spacer()
                    }
                }
                .padding()
            }
            .background(Color("Background"))
            .navigationTitle("envelope.create") // 봉투 만들기
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: BackButton(onDismiss: handleDismiss))
            .toolbarBackground(Color("Background"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("common.alert", isPresented: $showingAlert) { // 알림
                Button("common.ok", role: .cancel) { } // 확인
                if alertMessage.contains("envelope.persistent_premium_required".localized) {
                    Button("subscription.view_premium") { // 프리미엄 보기
                        showingSubscription = true
                    }
                }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    AddEnvelopeView()
}
