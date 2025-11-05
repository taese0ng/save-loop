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
    @Query(sort: \Envelope.createdAt) private var allEnvelopes: [Envelope]
    @Environment(\.modelContext) private var modelContext: ModelContext
    
    @State private var navigationPath: NavigationRoute?
    @EnvironmentObject private var dateSelection: DateSelectionState
    
    private var isCurrentMonth: Bool {
        dateSelection.isCurrentMonth
    }
    
    private var filteredEnvelopes: [Envelope] {
        let calendar: Calendar = Calendar.current
        return allEnvelopes
            .filter { envelope in
                calendar.component(.year, from: envelope.createdAt) == calendar.component(.year, from: dateSelection.selectedDate) &&
                calendar.component(.month, from: envelope.createdAt) == calendar.component(.month, from: dateSelection.selectedDate)
            }
    }

    func moveAddBalancePage() {
        navigationPath = .addBalance
    }
    
    func moveAddEnvelopePage() {
        navigationPath = .addEnvelope
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
                        onEnvelopeTap: moveDetailEnvelopePage
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
