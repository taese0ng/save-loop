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

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

}
