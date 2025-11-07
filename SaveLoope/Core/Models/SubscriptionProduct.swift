import Foundation

/// 구독 제품 식별자 및 메타데이터
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "dev.taeseong.SaveLoope.monthly"
    case yearly = "dev.taeseong.SaveLoope.yearly"
    case lifetime = "dev.taeseong.SaveLoope.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "월간 구독"
        case .yearly: return "연간 구독"
        case .lifetime: return "평생 이용권"
        }
    }

    var description: String {
        switch self {
        case .monthly: return "매월 자동 갱신"
        case .yearly: return "매년 자동 갱신 (2개월 무료)"
        case .lifetime: return "한 번 구매로 영구 사용"
        }
    }

    var icon: String {
        switch self {
        case .monthly: return "calendar"
        case .yearly: return "calendar.badge.clock"
        case .lifetime: return "infinity.circle.fill"
        }
    }
}

