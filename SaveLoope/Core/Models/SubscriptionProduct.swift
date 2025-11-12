import Foundation

/// 구독 제품 식별자 및 메타데이터
enum SubscriptionProduct: String, CaseIterable {
    case monthly = "dev.taeseong.SaveLoope.monthly"
    case yearly = "dev.taeseong.SaveLoope.yearly"
    case lifetime = "dev.taeseong.SaveLoope.lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "subscription.product.monthly.display_name".localized // 월간 구독
        case .yearly: return "subscription.product.yearly.display_name".localized // 연간 구독
        case .lifetime: return "subscription.product.lifetime.display_name".localized // 평생 이용권
        }
    }

    var description: String {
        switch self {
        case .monthly: return "subscription.product.monthly.description".localized // 매월 자동 갱신
        case .yearly: return "subscription.product.yearly.description".localized // 매년 자동 갱신
        case .lifetime: return "subscription.product.lifetime.description".localized // 한 번 구매로 영구 사용
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

