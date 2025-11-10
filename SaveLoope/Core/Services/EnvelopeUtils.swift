import Foundation
import SwiftData

/// 봉투 관련 유틸리티 함수들
enum EnvelopeUtils {
    /// 공통 NumberFormatter (천 단위 구분자 포함)
    static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        return formatter
    }()
    
    /// 정렬용 날짜 반환: 반복 봉투는 원본(parent)의 createdAt 사용
    static func getSortDate(for envelope: Envelope, in envelopes: [Envelope]) -> Date {
        // 반복 봉투이고 parentId가 있는 경우
        if envelope.type == .recurring, let parentId = envelope.parentId {
            // 원본 봉투 찾기
            if let parent = envelopes.first(where: { $0.id == parentId && $0.parentId == $0.id }) {
                return parent.createdAt
            }
        }
        // 그 외의 경우 자신의 createdAt 사용
        return envelope.createdAt
    }
    
    /// 선택된 날짜에 맞는 봉투들을 필터링하고 정렬
    static func filterAndSortEnvelopes(
        _ allEnvelopes: [Envelope],
        selectedDate: Date,
        calendar: Calendar = .current
    ) -> [Envelope] {
        let selectedYear = calendar.component(.year, from: selectedDate)
        let selectedMonth = calendar.component(.month, from: selectedDate)
        
        return allEnvelopes
            .filter { envelope in
                // 지속형 봉투는 항상 포함
                if envelope.type == .persistent {
                    return true
                }
                
                // 일반/반복 봉투는 선택된 월과 일치하는 것만
                return calendar.component(.year, from: envelope.createdAt) == selectedYear &&
                       calendar.component(.month, from: envelope.createdAt) == selectedMonth
            }
            .sorted { env1, env2 in
                // sortOrder가 0이면 Int.max로 취급 (맨 뒤로)
                let order1 = env1.sortOrder == 0 ? Int.max : env1.sortOrder
                let order2 = env2.sortOrder == 0 ? Int.max : env2.sortOrder
                
                if order1 != order2 {
                    return order1 < order2
                }
                
                // sortOrder가 같으면 날짜 기준 정렬
                let date1 = getSortDate(for: env1, in: allEnvelopes)
                let date2 = getSortDate(for: env2, in: allEnvelopes)
                return date1 < date2
            }
    }
}

