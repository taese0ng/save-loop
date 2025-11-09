import SwiftUI
import SwiftData

// Date를 Identifiable하게 만들기 위한 wrapper
struct IdentifiableDate: Identifiable {
    let id = UUID()
    let date: Date
}

// NavigationRoute enum for CalendarView
enum CalendarNavigationRoute: Hashable {
    case addBalance
    case addExpense
    
    static func == (lhs: CalendarNavigationRoute, rhs: CalendarNavigationRoute) -> Bool {
        switch (lhs, rhs) {
        case (.addBalance, .addBalance),
             (.addExpense, .addExpense):
            return true
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .addBalance:
            hasher.combine("addBalance")
        case .addExpense:
            hasher.combine("addExpense")
        }
    }
}

struct CalendarView: View {
    @EnvironmentObject private var dateSelection: DateSelectionState
    @ObservedObject private var currencyManager = CurrencyManager.shared
    @Query private var allTransactions: [TransactionRecord]

    @State private var selectedDateInfo: IdentifiableDate?
    @State private var navigationPath: CalendarNavigationRoute?

    private var calendar: Calendar {
        Calendar.current
    }

    private var currentMonthDate: Date {
        dateSelection.selectedDate
    }

    private var selectedYear: Int {
        calendar.component(.year, from: dateSelection.selectedDate)
    }

    private var selectedMonth: Int {
        calendar.component(.month, from: dateSelection.selectedDate)
    }

    // 현재 월의 첫 번째 날
    private var firstDayOfMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonthDate)) ?? currentMonthDate
    }

    // 현재 월의 첫 번째 날이 무슨 요일인지 (1=일요일, 7=토요일)
    private var firstWeekday: Int {
        calendar.component(.weekday, from: firstDayOfMonth)
    }

    // 현재 월의 총 일수
    private var numberOfDaysInMonth: Int {
        calendar.range(of: .day, in: .month, for: currentMonthDate)?.count ?? 30
    }

    // 현재 월의 전체 거래내역 합산
    private var monthlyTotals: (income: Double, expense: Double, balance: Double) {
        let monthTransactions = allTransactions.filter { transaction in
            calendar.component(.year, from: transaction.date) == selectedYear &&
            calendar.component(.month, from: transaction.date) == selectedMonth
        }

        var income: Double = 0
        var expense: Double = 0

        for transaction in monthTransactions {
            if transaction.type == .income {
                income += Double(transaction.amount)
            } else {
                expense += Double(transaction.amount)
            }
        }

        return (income, expense, income - expense)
    }

    // 날짜별 거래내역 합산 계산
    private func getTransactionTotal(for day: Int) -> (income: Double, expense: Double) {
        guard let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: day)) else {
            return (0, 0)
        }

        let dayTransactions = allTransactions.filter { transaction in
            calendar.isDate(transaction.date, inSameDayAs: date)
        }

        var income: Double = 0
        var expense: Double = 0

        for transaction in dayTransactions {
            if transaction.type == .income {
                income += Double(transaction.amount)
            } else {
                expense += Double(transaction.amount)
            }
        }

        return (income, expense)
    }

    // 42칸(6주)의 날짜 배열 생성
    private var calendarDays: [Int?] {
        var days: [Int?] = []

        // 첫 주의 빈 칸
        for _ in 1..<firstWeekday {
            days.append(nil)
        }

        // 실제 날짜들
        for day in 1...numberOfDaysInMonth {
            days.append(day)
        }

        // 나머지 빈 칸 (42칸 채우기)
        while days.count < 42 {
            days.append(nil)
        }

        return days
    }

    func moveAddBalancePage() {
        navigationPath = .addBalance
    }
    
    func moveAddExpensePage() {
        navigationPath = .addExpense
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 헤더 (홈과 동일한 컴포넌트 재활용)
                HeaderView(currentDate: $dateSelection.selectedDate)

                // 월별 요약 섹션
                MonthSummaryView(
                    totalIncome: monthlyTotals.income,
                    totalExpense: monthlyTotals.expense,
                    balance: monthlyTotals.balance
                )
                .padding(.horizontal)
                .padding(.vertical, 16)

                // 요일 헤더
                HStack(spacing: 0) {
                    ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(day == "일" ? .red : day == "토" ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 12)

                // 스크롤 가능한 달력 그리드
                GeometryReader { geometry in
                    let availableHeight = geometry.size.height
                    let weekHeight = availableHeight / 6
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<6, id: \.self) { week in
                                HStack(spacing: 0) {
                                    ForEach(0..<7, id: \.self) { weekday in
                                        let index = week * 7 + weekday
                                        let day = calendarDays[index]

                                        if let day = day {
                                            CalendarDayCell(
                                                day: day,
                                                year: selectedYear,
                                                month: selectedMonth,
                                                income: getTransactionTotal(for: day).income,
                                                expense: getTransactionTotal(for: day).expense
                                            )
                                            .onTapGesture {
                                                if let date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: day)) {
                                                    selectedDateInfo = IdentifiableDate(date: date)
                                                }
                                            }
                                        } else {
                                            Rectangle()
                                                .fill(Color.white)
                                        }
                                    }
                                }
                                .frame(height: weekHeight)
                            }
                        }
                        .overlay(
                            // 세로 그리드 선
                            HStack(spacing: 0) {
                                ForEach(0..<8, id: \.self) { i in
                                    if i > 0 {
                                        Spacer()
                                    }
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 0.5)
                                }
                            }
                        )
                        .overlay(
                            // 가로 그리드 선
                            VStack(spacing: 0) {
                                ForEach(0..<7, id: \.self) { i in
                                    if i > 0 {
                                        Spacer()
                                    }
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 0.5)
                                }
                            }
                        )
                    }
                }
                
                // 잔액추가/지출 버튼
                BalanceTabs(onAddBalance: moveAddBalancePage, onAddExpense: moveAddExpensePage)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .navigationDestination(item: $navigationPath) { route in
                switch route {
                case .addBalance:
                    AddBalanceView()
                        .toolbar(.hidden, for: .navigationBar)
                        .environmentObject(dateSelection)
                case .addExpense:
                    AddExpenseView()
                        .toolbar(.hidden, for: .navigationBar)
                        .environmentObject(dateSelection)
                }
            }
            .sheet(item: $selectedDateInfo) { dateInfo in
                DayTransactionSheet(
                    date: dateInfo.date,
                    transactions: allTransactions.filter { transaction in
                        calendar.isDate(transaction.date, inSameDayAs: dateInfo.date)
                    }
                )
            }
        }
    }
}

#Preview {
    do {
        let container = try ModelContainer(for: TransactionRecord.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))

        return CalendarView()
            .modelContainer(container)
            .environmentObject(DateSelectionState())
    } catch {
        return Text("Error setting up preview: \(error.localizedDescription)")
    }
}
