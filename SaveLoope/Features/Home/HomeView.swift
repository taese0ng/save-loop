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
    @ObservedObject private var viewModel = HomeViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
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

        // 해당 월의 첫날로 정규화
        let normalizedDate = calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
        let normalizedThreeMonthsAgo = calendar.date(from: calendar.dateComponents([.year, .month], from: threeMonthsAgo)) ?? threeMonthsAgo

        return normalizedDate >= normalizedThreeMonthsAgo
    }

    private var filteredEnvelopes: [Envelope] {
        let calendar: Calendar = Calendar.current
        let selectedDate = dateSelection.selectedDate

        // 무료 사용자이고 3개월 이전 데이터를 조회하려는 경우 빈 배열 반환
        if !subscriptionManager.isSubscribed && !isWithinThreeMonths(selectedDate) {
            return []
        }

        return allEnvelopes
            .filter { envelope in
                // 지속형 봉투는 항상 표시
                if envelope.type == .persistent {
                    return true
                }

                // 일반/반복 봉투는 선택된 월과 일치하는 것만 표시
                return calendar.component(.year, from: envelope.createdAt) == calendar.component(.year, from: selectedDate) &&
                       calendar.component(.month, from: envelope.createdAt) == calendar.component(.month, from: selectedDate)
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
            if let parent = allEnvelopes.first(where: { $0.id == parentId && $0.parentId == $0.id }) {
                return parent.createdAt
            }
        }
        // 그 외의 경우 자신의 createdAt 사용
        return envelope.createdAt
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
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        // 현재 월에 생성된 봉투만 카운트 (지속형 봉투는 최초 생성 월에만 카운트)
        let currentMonthCreatedCount = allEnvelopes.filter { envelope in
            calendar.component(.year, from: envelope.createdAt) == currentYear &&
            calendar.component(.month, from: envelope.createdAt) == currentMonth
        }.count

        // 프리미엄 기능 체크
        let canCreate = PremiumFeatureManager.shared.canCreateMoreEnvelopes(
            currentCount: currentMonthCreatedCount,
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
                        Text("봉투가 존재하지 않습니다.")
                            .font(.title3)
                            .foregroundColor(.gray)
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
            .background(Color.white)
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
            .alert("제한 도달", isPresented: $showingLimitAlert) {
                Button("취소", role: .cancel) { }
                Button("프리미엄 보기") {
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
