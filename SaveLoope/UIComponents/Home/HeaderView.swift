import SwiftUI

struct HeaderView: View {
    @Binding var currentDate: Date
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared

    @State private var showingDatePicker: Bool = false
    @State private var selectedYear: Int
    @State private var selectedMonth: Int
    @State private var showingMonthLimitAlert = false
    @State private var showingSubscription = false

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
        let calendar = Calendar.current
        let year = calendar.component(.year, from: currentDate)
        let month = calendar.component(.month, from: currentDate)
        return "\(year)년 \(month)월"
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

    private func updateDate() {
        let calendar: Calendar = Calendar.current
        if let newDate: Date = calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth)) {
            // 무료 사용자이고 3개월 이전 데이터면 접근 차단
            if !subscriptionManager.isSubscribed && !isWithinThreeMonths(newDate) {
                showingMonthLimitAlert = true
                return
            }
            currentDate = newDate
        }
    }

    private func moveToPreviousMonth() {
        if let newDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: currentDate) {
            // 무료 사용자이고 3개월 이전 데이터면 접근 차단
            if !subscriptionManager.isSubscribed && !isWithinThreeMonths(newDate) {
                showingMonthLimitAlert = true
                return
            }

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
                ZStack {
                    Circle()
                        .fill(Color("Separator"))
                        .frame(width: 38, height: 38)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Color("PrimaryText"))
                }
                .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .fixedSize()

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
                .presentationDragIndicator(.visible)
            }

            Spacer()

            Button(action: moveToNextMonth) {
                ZStack {
                    Circle()
                        .fill(Color("Separator"))
                        .frame(width: 38, height: 38)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(isCurrentMonth ? Color("SecondaryText") : Color("PrimaryText"))
                }
                .contentShape(Circle())
            }
            .buttonStyle(PlainButtonStyle())
            .fixedSize()
            .disabled(isCurrentMonth)
        }
        .padding(.horizontal)
        .alert("제한 도달", isPresented: $showingMonthLimitAlert) {
            Button("취소", role: .cancel) { }
            Button("프리미엄 보기") {
                showingSubscription = true
            }
        } message: {
            Text(PremiumFeatureManager.shared.getMonthLimitMessage())
        }
        .sheet(isPresented: $showingSubscription) {
            SubscriptionView()
        }
    }
}

#Preview {
    HeaderView(currentDate: .constant(Date()))
}
