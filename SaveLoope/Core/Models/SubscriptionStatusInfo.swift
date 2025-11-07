import Foundation
import StoreKit

/// 구독 상태
enum SubscriptionStatus {
    case notSubscribed
    case subscribed(Product)
    case expired
}

/// 구독 정보 (갱신 예정, 변경 예정 등)
struct SubscriptionInfo {
    let currentProduct: Product
    let willRenew: Bool
    let renewalDate: Date?
    let pendingProduct: Product?

    var isPendingChange: Bool {
        pendingProduct != nil && pendingProduct?.id != currentProduct.id
    }
}

