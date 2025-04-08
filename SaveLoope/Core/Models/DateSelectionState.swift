import SwiftUI

// 날짜 선택 상태를 관리하는 환경 객체
class DateSelectionState: ObservableObject {
    @Published var selectedDate: Date = Date()
    
    var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
} 