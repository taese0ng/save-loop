import Foundation
import SwiftUI

/// 봉투 갱신일을 관리하는 매니저
/// 월별 봉투 갱신이 시작되는 날짜를 설정합니다 (예: 1일, 25일 등)
@MainActor
class RenewalDayManager: ObservableObject {
    @MainActor static let shared = RenewalDayManager()
    
    /// 갱신일 (1-31일, 기본값: 1일)
    @Published var renewalDay: Int {
        didSet {
            UserDefaults.standard.set(renewalDay, forKey: "envelopeRenewalDay")
        }
    }
    
    private let renewalDayKey = "envelopeRenewalDay"
    private let defaultRenewalDay = 1
    
    private init() {
        // 저장된 갱신일 불러오기
        let savedDay = UserDefaults.standard.integer(forKey: renewalDayKey)
        // 유효한 범위(1-31)인지 확인
        if savedDay >= 1 && savedDay <= 31 {
            self.renewalDay = savedDay
        } else {
            self.renewalDay = defaultRenewalDay
        }
    }
    
    /// 갱신일 변경
    func setRenewalDay(_ day: Int) {
        guard day >= 1 && day <= 31 else {
            print("⚠️ 갱신일은 1-31 사이의 값이어야 합니다.")
            return
        }
        renewalDay = day
    }
    
    /// 특정 날짜가 속한 갱신 주기를 계산
    /// 갱신일이 25일인 경우:
    /// - 1월 25일 ~ 2월 24일 → 1월 주기
    /// - 2월 25일 ~ 3월 24일 → 2월 주기
    func getRenewalCycle(for date: Date) -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        // 갱신일 이전이면 이전 달이 주기의 시작
        if day < renewalDay {
            // 이전 달 계산
            if let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) {
                let prevYear = calendar.component(.year, from: previousMonth)
                let prevMonth = calendar.component(.month, from: previousMonth)
                return (prevYear, prevMonth)
            }
        }
        
        return (year, month)
    }
    
    /// 두 날짜가 같은 갱신 주기에 속하는지 확인
    func isSameRenewalCycle(_ date1: Date, _ date2: Date) -> Bool {
        let cycle1 = getRenewalCycle(for: date1)
        let cycle2 = getRenewalCycle(for: date2)
        return cycle1.year == cycle2.year && cycle1.month == cycle2.month
    }
}

