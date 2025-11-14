import Foundation
import SwiftUI

/// 봉투 갱신일을 관리하는 매니저
/// 월별 봉투 갱신이 시작되는 날짜를 설정합니다 (예: 1일, 25일, 말일 등)
@MainActor
class RenewalDayManager: ObservableObject {
    @MainActor static let shared = RenewalDayManager()
    
    /// 갱신일 (1-28일, 0=말일, 기본값: 1일)
    @Published var renewalDay: Int {
        didSet {
            UserDefaults.standard.set(renewalDay, forKey: "envelopeRenewalDay")
        }
    }
    
    private let renewalDayKey = "envelopeRenewalDay"
    private let defaultRenewalDay = 1
    
    /// 말일을 나타내는 특수 값
    static let lastDayOfMonth = 0
    
    private init() {
        // 저장된 갱신일 불러오기
        let savedDay = UserDefaults.standard.integer(forKey: renewalDayKey)
        // 유효한 범위(0=말일, 1-28일)인지 확인
        // 기존 사용자를 위해 29-31일도 허용하되 28일로 조정
        if savedDay == 0 {
            self.renewalDay = savedDay // 말일
        } else if savedDay >= 1 && savedDay <= 28 {
            self.renewalDay = savedDay
        } else if savedDay >= 29 && savedDay <= 31 {
            // 기존 사용자의 29-31일 설정은 28일로 마이그레이션
            self.renewalDay = 28
            print("ℹ️ 갱신일이 \(savedDay)일에서 28일로 조정되었습니다.")
        } else {
            self.renewalDay = defaultRenewalDay
        }
    }
    
    /// 갱신일 변경
    func setRenewalDay(_ day: Int) {
        guard (day >= 1 && day <= 28) || day == RenewalDayManager.lastDayOfMonth else {
            print("⚠️ 갱신일은 1-28 사이의 값 또는 말일(0)이어야 합니다.")
            return
        }
        renewalDay = day
    }
    
    /// 갱신일이 말일인지 확인
    var isLastDayOfMonth: Bool {
        return renewalDay == RenewalDayManager.lastDayOfMonth
    }
    
    /// 특정 월의 실질적인 갱신일 계산 (말일 처리 포함)
    /// - Parameters:
    ///   - year: 연도
    ///   - month: 월
    /// - Returns: 실질적인 갱신일 (1-31)
    func getEffectiveRenewalDay(year: Int, month: Int) -> Int {
        if isLastDayOfMonth {
            // 말일인 경우 해당 월의 마지막 날 계산
            let calendar = Calendar.current
            guard let date = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  let range = calendar.range(of: .day, in: .month, for: date) else {
                return 28 // 실패 시 기본값
            }
            return range.count
        } else {
            return renewalDay
        }
    }
    
    /// 특정 날짜의 실질적인 갱신일 계산
    func getEffectiveRenewalDay(for date: Date) -> Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        return getEffectiveRenewalDay(year: year, month: month)
    }
    
    /// 특정 날짜가 속한 갱신 주기를 계산
    /// 갱신일이 25일인 경우:
    /// - 1월 25일 ~ 2월 24일 → 1월 주기
    /// - 2월 25일 ~ 3월 24일 → 2월 주기
    /// 말일인 경우:
    /// - 1월 31일 ~ 2월 28일(또는 29일) → 1월 주기
    /// - 3월 31일 ~ 4월 30일 → 3월 주기
    func getRenewalCycle(for date: Date) -> (year: Int, month: Int) {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        // 해당 월의 실질적인 갱신일 계산
        let effectiveRenewalDay = getEffectiveRenewalDay(year: year, month: month)
        
        // 갱신일 이전이면 이전 달이 주기의 시작
        if day < effectiveRenewalDay {
            // 이전 달 계산
            if let previousMonth = calendar.date(byAdding: .month, value: -1, to: date) {
                let prevYear = calendar.component(.year, from: previousMonth)
                let prevMonth = calendar.component(.month, from: previousMonth)
                return (prevYear, prevMonth)
            }
        }
        
        return (year, month)
    }
    
    /// 특정 갱신 주기의 시작일을 안전하게 계산
    /// - Parameters:
    ///   - year: 연도
    ///   - month: 월
    /// - Returns: 갱신 주기 시작일
    func getCycleStartDate(year: Int, month: Int) -> Date? {
        let calendar = Calendar.current
        let effectiveRenewalDay = getEffectiveRenewalDay(year: year, month: month)
        return calendar.date(from: DateComponents(year: year, month: month, day: effectiveRenewalDay))
    }
    
    /// 두 날짜가 같은 갱신 주기에 속하는지 확인
    func isSameRenewalCycle(_ date1: Date, _ date2: Date) -> Bool {
        let cycle1 = getRenewalCycle(for: date1)
        let cycle2 = getRenewalCycle(for: date2)
        return cycle1.year == cycle2.year && cycle1.month == cycle2.month
    }
}

