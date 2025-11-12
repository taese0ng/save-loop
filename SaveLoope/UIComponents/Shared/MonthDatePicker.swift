import SwiftUI

public struct MonthDatePicker: View {
    @Binding var selectedMonth: Int
    @Binding var selectedYear: Int
    @State private var currentMonth: Int
    @State private var currentYear: Int
    
    // 실제로 선택된(확정된) 년도와 월을 추적
    @State private var confirmedYear: Int
    @State private var confirmedMonth: Int
    
    // 월 선택 시 호출될 클로저 추가
    var onMonthSelected: (() -> Void)?
    
    private let months: [Int] = Array(1...12)
    private let columns: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)
    
    public init(selectedMonth: Binding<Int>, selectedYear: Binding<Int>, onMonthSelected: (() -> Void)? = nil) {
        self._selectedMonth = selectedMonth
        self._selectedYear = selectedYear
        let calendar: Calendar = Calendar.current
        let currentDate: Date = Date()
        self._currentMonth = State(initialValue: calendar.component(.month, from: currentDate))
        self._currentYear = State(initialValue: calendar.component(.year, from: currentDate))
        
        // 초기값은 현재 바인딩된 값으로 설정
        self._confirmedYear = State(initialValue: selectedYear.wrappedValue)
        self._confirmedMonth = State(initialValue: selectedMonth.wrappedValue)
        
        self.onMonthSelected = onMonthSelected
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Year Selection
            HStack {
                Button(action: { selectedYear -= 1 }) {
                    ZStack {
                        Circle()
                            .fill(Color("DividerColor"))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color("PrimaryText"))
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(String(format: "date.format.year".localized, selectedYear)) // %d년
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color("PrimaryText"))
                    .frame(width: 100)

                Button(action: {
                    if selectedYear < currentYear {
                        selectedYear += 1
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color("DividerColor"))
                            .frame(width: 40, height: 40)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(selectedYear < currentYear ? Color("PrimaryText") : Color("SecondaryText"))
                    }
                    .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .fixedSize()
                .frame(maxWidth: .infinity, alignment: .trailing)
                .disabled(selectedYear >= currentYear)
            }
            .padding(.horizontal)
            
            // Month Grid
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(months, id: \.self) { month in
                    MonthButton(
                        month: month,
                        isSelected: isMonthSelected(month: month),
                        isEnabled: isMonthEnabled(month: month),
                        action: { 
                            // 월을 클릭하면 선택된 년도와 월을 확정
                            confirmedYear = selectedYear
                            confirmedMonth = month
                            // 바인딩된 값도 업데이트
                            selectedMonth = month
                            
                            // 월 선택 시 콜백 호출
                            onMonthSelected?()
                        }
                    )
                }
            }
            .padding()
        }
    }
    
    private func isMonthSelected(month: Int) -> Bool {
        // 현재 보여지는 년도가 확정된 년도와 같고, 월이 확정된 월과 같은 경우에만 선택 표시
        return selectedYear == confirmedYear && month == confirmedMonth
    }
    
    private func isMonthEnabled(month: Int) -> Bool {
        if selectedYear < currentYear {
            return true
        } else if selectedYear == currentYear {
            return month <= currentMonth
        } else {
            return false
        }
    }
}

struct MonthButton: View {
    let month: Int
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(String(format: "date.format.month".localized, month)) // %d월
                .font(.system(size: 16, weight: .medium))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color("PrimaryText").opacity(0.2) : Color("DividerColor"))
                .foregroundColor(isSelected ? Color("PrimaryText") : (isEnabled ? Color("PrimaryText") : Color("SecondaryText")))
                .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

struct MonthDatePicker_Previews: PreviewProvider {
    static var previews: some View {
        PreviewWrapper()
    }
    
    struct PreviewWrapper: View {
        @State private var selectedMonth: Int = 5
        @State private var selectedYear: Int = 2024
        
        var body: some View {
            MonthDatePicker(selectedMonth: $selectedMonth, selectedYear: $selectedYear)
        }
    }
}
