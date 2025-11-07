import SwiftUI
import SwiftData

struct CalendarView: View {
    @EnvironmentObject private var dateSelection: DateSelectionState
    @Query private var allTransactions: [TransactionRecord]

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

    var body: some View {
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
            .padding(.horizontal, 8)
            .padding(.vertical, 12)

            // 스크롤 가능한 달력 그리드
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
                                } else {
                                    Rectangle()
                                        .fill(Color.white)
                                        .frame(height: 80)
                                }
                            }
                        }
                        .frame(height: 80)
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
                .padding(.horizontal, 8)
            }
        }
        .background(Color.white)
    }
}

// 월별 요약 섹션
struct MonthSummaryView: View {
    let totalIncome: Double
    let totalExpense: Double
    let balance: Double

    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "0"
    }

    var body: some View {
        HStack(spacing: 16) {
            // 총 수입
            VStack(alignment: .leading, spacing: 4) {
                Text("총 수입")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("+\(formatAmount(totalIncome))원")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.blue)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 총 지출
            VStack(alignment: .leading, spacing: 4) {
                Text("총 지출")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("-\(formatAmount(totalExpense))원")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 총액
            VStack(alignment: .leading, spacing: 4) {
                Text("총액")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("\(balance >= 0 ? "+" : "")\(formatAmount(balance))원")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(balance >= 0 ? .blue : .red)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// 개별 날짜 셀
struct CalendarDayCell: View {
    let day: Int
    let year: Int
    let month: Int
    let income: Double
    let expense: Double

    private var isToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.component(.year, from: today) == year &&
               calendar.component(.month, from: today) == month &&
               calendar.component(.day, from: today) == day
    }

    private var weekday: Int {
        let calendar = Calendar.current
        if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
            return calendar.component(.weekday, from: date)
        }
        return 0
    }

    private var dayColor: Color {
        if weekday == 1 { // 일요일
            return .red
        } else if weekday == 7 { // 토요일
            return .blue
        } else {
            return .primary
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("\(day)")
                .font(.system(size: 17, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : dayColor)
                .frame(width: 30, height: 30)
                .background(isToday ? Color.blue : Color.clear)
                .clipShape(Circle())
                .padding(.top, 6)

            VStack(spacing: 2) {
                if income > 0 {
                    Text("+\(formatAmount(income))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }

                if expense > 0 {
                    Text("-\(formatAmount(expense))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
            .padding(.horizontal, 2)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func formatAmount(_ amount: Double) -> String {
        if amount >= 10000 {
            let man = Int(amount / 10000)
            return "\(man)만"
        } else if amount >= 1000 {
            let thousand = Int(amount / 1000)
            return "\(thousand)천"
        } else {
            return "\(Int(amount))"
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
