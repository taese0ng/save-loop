import SwiftUI

struct MonthCalendarView: View {
    let selectedDate: Date
    @Binding var date: Date
    
    private let calendar: Calendar = Calendar.current
    
    private var currentMonth: Int {
        calendar.component(.month, from: selectedDate)
    }
    
    private var currentYear: Int {
        calendar.component(.year, from: selectedDate)
    }
    
    private var daysInMonth: Int {
        calendar.range(of: .day, in: .month, for: selectedDate)!.count
    }
    
    var body: some View {
        VStack {
            Text("\(String(format: "%d", currentYear)).\(String(format: "%02d", currentMonth))")
                .font(.title2)
                .padding()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(1...daysInMonth, id: \.self) { day in
                    Button(action: {
                        if let newDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)) {
                            date = newDate
                        }
                    }) {
                        ZStack {
                            Text("\(day)")
                                .frame(width: 40, height: 40)
                                .background(calendar.component(.day, from: date) == day ? Color.blue : Color.clear)
                                .foregroundColor(calendar.component(.day, from: date) == day ? .white : .primary)
                                .cornerRadius(20)
                            
                            if calendar.isDateInToday(calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day))!) {
                                Circle()
                                    .fill(calendar.component(.day, from: date) == day ? Color.white : Color.blue)
                                    .frame(width: 4, height: 4)
                                    .offset(y: 12)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    MonthCalendarView(selectedDate: Date(), date: .constant(Date()))
} 