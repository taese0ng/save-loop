import SwiftUI
import SwiftData
import Foundation

enum NavigationRoute: Hashable {
    case addEnvelope
    case addBalance
    case addExpense
    case detailEnvelope(Envelope)
    
    static func == (lhs: NavigationRoute, rhs: NavigationRoute) -> Bool {
        switch (lhs, rhs) {
        case (.addEnvelope, .addEnvelope),
             (.addBalance, .addBalance),
             (.addExpense, .addExpense):
            return true
        case (.detailEnvelope(let lhsEnvelope), .detailEnvelope(let rhsEnvelope)):
            return lhsEnvelope == rhsEnvelope
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .addEnvelope:
            hasher.combine("addEnvelope")
        case .addBalance:
            hasher.combine("addBalance")
        case .addExpense:
            hasher.combine("addExpense")
        case .detailEnvelope(let envelope):
            hasher.combine("detailEnvelope")
            hasher.combine(envelope)
        }
    }
}

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Query private var allEnvelopes: [Envelope]
    @Environment(\.modelContext) private var modelContext: ModelContext

    @State private var navigationPath: NavigationRoute?
    @State private var showingLimitAlert = false
    @State private var showingSubscription = false
    @State private var editMode: EditMode = .inactive
    @EnvironmentObject private var dateSelection: DateSelectionState
    
    private var isCurrentMonth: Bool {
        dateSelection.isCurrentMonth
    }

    /// 특정 날짜가 최근 3개월 이내인지 확인
    private func isWithinThreeMonths(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()

        // 3개월 전 날짜 계산
        guard let threeMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now) else {
            return false
        }

        // 해당 월의 첫날로 정규화 (한 번만 계산)
        let dateComponents = calendar.dateComponents([.year, .month], from: date)
        let threeMonthsAgoComponents = calendar.dateComponents([.year, .month], from: threeMonthsAgo)
        
        guard let normalizedDate = calendar.date(from: dateComponents),
              let normalizedThreeMonthsAgo = calendar.date(from: threeMonthsAgoComponents) else {
            return false
        }

        return normalizedDate >= normalizedThreeMonthsAgo
    }

    private var filteredEnvelopes: [Envelope] {
        let selectedDate = dateSelection.selectedDate

        // 무료 사용자이고 3개월 이전 데이터를 조회하려는 경우 빈 배열 반환
        if !subscriptionManager.isSubscribed && !isWithinThreeMonths(selectedDate) {
            return []
        }

        return EnvelopeUtils.filterAndSortEnvelopes(allEnvelopes, selectedDate: selectedDate)
    }

    // 봉투 순서 변경
    private func moveEnvelope(from source: IndexSet, to destination: Int) {
        var envelopes = filteredEnvelopes
        envelopes.move(fromOffsets: source, toOffset: destination)

        // sortOrder 재설정 (1부터 시작)
        for (index, envelope) in envelopes.enumerated() {
            envelope.sortOrder = index + 1
            
            // 반복 봉투인 경우 원본 봉투(parentId == id인 봉투)의 sortOrder도 동기화
            if envelope.type == .recurring, let parentId = envelope.parentId {
                if let parentEnvelope = allEnvelopes.first(where: { $0.id == parentId && $0.parentId == $0.id }) {
                    parentEnvelope.sortOrder = index + 1
                    // 원본 봉투의 반복 속성 명시적으로 보존
                    parentEnvelope.isRecurring = true
                    parentEnvelope.type = .recurring
                }
            }
        }

        // 저장
        do {
            try modelContext.save()
            print("✅ 봉투 순서 변경 저장 완료")
        } catch {
            print("❌ 봉투 순서 저장 실패: \(error.localizedDescription)")
        }
    }

    func moveAddBalancePage() {
        navigationPath = .addBalance
    }
    
    func moveAddEnvelopePage() {
        let now = Date()
        let renewalDayManager = RenewalDayManager.shared
        let currentCycle = renewalDayManager.getRenewalCycle(for: now)

        // 현재 갱신 주기에 생성된 봉투만 카운트 (지속형 봉투는 최초 생성 갱신 주기에만 카운트)
        let currentCycleCreatedCount = allEnvelopes.filter { envelope in
            if envelope.type == .persistent {
                // 지속형 봉투는 생성 갱신 주기 기준
                let envelopeCycle = renewalDayManager.getRenewalCycle(for: envelope.createdAt)
                return envelopeCycle.year == currentCycle.year && envelopeCycle.month == currentCycle.month
            } else {
                // 일반/반복 봉투는 현재 갱신 주기 기준
                let envelopeCycle = renewalDayManager.getRenewalCycle(for: envelope.createdAt)
                return envelopeCycle.year == currentCycle.year && envelopeCycle.month == currentCycle.month
            }
        }.count

        // 프리미엄 기능 체크
        let canCreate = PremiumFeatureManager.shared.canCreateMoreEnvelopes(
            currentCount: currentCycleCreatedCount,
            isSubscribed: subscriptionManager.isSubscribed
        )

        if canCreate {
            navigationPath = .addEnvelope
        } else {
            showingLimitAlert = true
        }
    }

    func moveAddExpensePage() {
        navigationPath = .addExpense
    }
    
    func moveDetailEnvelopePage(_ envelope: Envelope) {
        navigationPath = .detailEnvelope(envelope)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HeaderView(currentDate: $dateSelection.selectedDate)
                
                if filteredEnvelopes.isEmpty {
                    Spacer()
                    if isCurrentMonth {
                        EmptyStateView(onAddEnvelope: moveAddEnvelopePage)
                    } else {
                        Text("home.no_envelopes".localized) // 봉투가 존재하지 않습니다.
                            .font(.title3)
                            .foregroundColor(Color("SecondaryText"))
                    }
                    Spacer()
                } else {
                    EnvelopeListView(
                        hasNotAddButton: !isCurrentMonth,
                        envelopes: filteredEnvelopes,
                        onAddEnvelope: isCurrentMonth ? moveAddEnvelopePage : {},
                        onEnvelopeTap: moveDetailEnvelopePage,
                        onMove: isCurrentMonth ? moveEnvelope : nil,
                        editMode: $editMode
                    )
                    .padding(.top, 35)
                    BalanceTabs(onAddBalance: moveAddBalancePage, onAddExpense: moveAddExpensePage)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Background"))
            .navigationDestination(item: $navigationPath) { route in
                switch route {
                    case .addEnvelope:
                        AddEnvelopeView()
                            .toolbar(.hidden, for: .navigationBar)
                    case .addBalance:
                        AddBalanceView()
                            .toolbar(.hidden, for: .navigationBar)
                            .environmentObject(dateSelection)
                    case .addExpense:
                        AddExpenseView()
                            .toolbar(.hidden, for: .navigationBar)
                            .environmentObject(dateSelection)
                    case .detailEnvelope(let envelope):
                        DetailEnvelopeView(envelope: envelope)
                            .toolbar(.hidden, for: .navigationBar)
                }
            }
            .onAppear {
                viewModel.checkAndCreateRecurringEnvelopes(using: modelContext)

                // 무료 사용자가 3개월 이전 데이터를 보고 있으면 현재 월로 이동
                if !subscriptionManager.isSubscribed && !isWithinThreeMonths(dateSelection.selectedDate) {
                    dateSelection.selectedDate = Date()
                }
            }
            .alert("envelope.limit_reached", isPresented: $showingLimitAlert) { // 제한 도달
                Button("common.cancel", role: .cancel) { } // 취소
                Button("subscription.view_premium") { // 프리미엄 보기
                    showingSubscription = true
                }
            } message: {
                Text(PremiumFeatureManager.shared.getEnvelopeLimitMessage())
            }
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }
}

#Preview {
    do {
        // 인메모리 SwiftData 컨테이너 생성
        let container = try ModelContainer(for: Envelope.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        
        // 더미 데이터 추가
        let context = container.mainContext
        let calendar = Calendar.current
        let currentDate = Date()
        
        // 현재 월의 봉투들
        let currentMonthEnvelopes = [
            Envelope(name: "식비", budget: 500000, income:10000, spent: 200000, goal: 0),
            Envelope(name: "교통비", budget: 100000, income:0, spent: 50000, goal: 0),
            Envelope(name: "쇼핑", budget: 300000, income:0, spent: 100000, goal: 0)
        ]
        
        // 이전 월의 봉투들
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: currentDate) {
            let lastMonthEnvelopes = [
                Envelope(name: "식비", budget: 500000, income:0, spent: 200000, goal: 0),
                Envelope(name: "교통비", budget: 100000, income:0, spent: 50000, goal: 0),
                Envelope(name: "쇼핑", budget: 300000, income:0, spent: 100000, goal: 0)
            ]
            
            for envelope in lastMonthEnvelopes {
                envelope.createdAt = lastMonth
                context.insert(envelope)
            }
        }
        
        for envelope in currentMonthEnvelopes {
            context.insert(envelope)
        }
        
        return HomeView()
            .modelContainer(container)
            .environmentObject(DateSelectionState())
    } catch {
        return Text("Error setting up preview: \(error.localizedDescription)")
    }
}
