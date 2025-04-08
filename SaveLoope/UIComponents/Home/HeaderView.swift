import SwiftUI

struct HeaderView: View {
    @Binding var currentDate: Date
    
    @State private var showingDatePicker: Bool = false
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    
    init(currentDate: Binding<Date>) {
        self._currentDate = currentDate
        let calendar: Calendar = Calendar.current
        let date: Date = currentDate.wrappedValue
        self._selectedYear = State(initialValue: calendar.component(.year, from: date))
        self._selectedMonth = State(initialValue: calendar.component(.month, from: date))
    }
    
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(currentDate, equalTo: Date(), toGranularity: .month)
    }
    
    private var formattedDate: String {
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월"
        return formatter.string(from: currentDate)
    }
    
    private func updateDate() {
        let calendar: Calendar = Calendar.current
        if let newDate: Date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth)) {
            currentDate = newDate
        }
    }
    
    private func moveToPreviousMonth() {
        if let newDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            currentDate = newDate
            let calendar: Calendar = Calendar.current
            selectedYear = calendar.component(.year, from: newDate)
            selectedMonth = calendar.component(.month, from: newDate)
        }
    }
    
    private func moveToNextMonth() {
        if !isCurrentMonth {
            if let newDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: currentDate) {
                currentDate = newDate
                let calendar: Calendar = Calendar.current
                selectedYear = calendar.component(.year, from: newDate)
                selectedMonth = calendar.component(.month, from: newDate)
            }
        }
    }

    var body: some View {
        HStack {
            Button(action: moveToPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Button(action: {
                showingDatePicker = true
            }) {
                Text(formattedDate)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .sheet(isPresented: $showingDatePicker) {
                NavigationView {
                    MonthDatePicker(
                        selectedMonth: $selectedMonth,
                        selectedYear: $selectedYear,
                        onMonthSelected: {
                            updateDate()
                            showingDatePicker = false
                        }
                    )
                }
                .presentationDetents([.height(400)])
            }
            
            Spacer()
            
            Button(action: moveToNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(isCurrentMonth ? .gray : .primary)
            }
            .disabled(isCurrentMonth)
        }
        .padding(.horizontal)
    }
}

#Preview {
    HeaderView(currentDate: .constant(Date()))
}
