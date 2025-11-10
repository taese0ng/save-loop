import SwiftUI

struct CalendarDayCell: View {
    let day: Int
    let year: Int
    let month: Int
    let income: Double
    let expense: Double
    @ObservedObject private var currencyManager = CurrencyManager.shared

    private var isToday: Bool {
        let calendar = Calendar.current
        let today = Date()
        let todayComponents = calendar.dateComponents([.year, .month, .day], from: today)
        return todayComponents.year == year &&
               todayComponents.month == month &&
               todayComponents.day == day
    }

    private var weekday: Int {
        let calendar = Calendar.current
        guard let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) else {
            return 0
        }
        return calendar.component(.weekday, from: date)
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
                .font(.system(size: 15, weight: isToday ? .bold : .regular))
                .foregroundColor(isToday ? .white : dayColor)
                .frame(height: 20)
                .padding(.horizontal, 12)
                .background(isToday ? Color.blue : Color.clear)
                .clipShape(Capsule())
                .padding(.top, 6)

            VStack(spacing: 2) {
                if income > 0 {
                    Text("+\(income.formattedCurrency)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.blue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                if expense > 0 {
                    Text("-\(expense.formattedCurrency)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.red)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
            .padding(.horizontal, 2)

            Spacer(minLength: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

}
