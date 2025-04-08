import SwiftUI
import StoreKit

class SubscriptionService: ObservableObject {
    @Published var isSubscribed: Bool = false  // 구독 활성화 여부
    
    // 구매 가능한 상품 리스트 (예: 월간/연간 구독) - 실제 제품 ID로 초기화 필요
    @Published var products: [Product] = []
    
    init() {
        // 앱 시작 시 구독 상태 갱신 (예: 기존 구독 여부 확인)
        Task { await updateSubscriptionStatus() }
        // 앱 시작 시 판매중인 상품 목록을 가져옴
        Task { await fetchProducts() }
    }
    
    /// App Store Connect에 등록한 인앱 상품(Product) 정보를 가져오기
    func fetchProducts() async {
        do {
            // 실제 구독 상품의 productIdentifier 배열로 대체해야 함
            let productIds: Set<String> = ["com.yourcompany.saveloope.premium"]
            products = try await Product.products(for: productIds)
        } catch {
            print("⚠️ Failed to fetch products: \(error)")
        }
    }
    
    /// 구독 상품 구매 시도 (예: "프리미엄 구독")
    func purchase(subscription product: Product) async {
        do {
            let result = try await product.purchase()  // 구매 프로세스 시작
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    // ✅ 구매 성공 및 검증됨
                    await transaction.finish()  // 트랜잭션 종료
                    isSubscribed = true         // 구독 상태 활성화
                    print("Purchase succeeded: \(transaction.id)")
                }
            case .userCancelled:
                // 구매 취소됨
                print("Purchase cancelled by user.")
            case .pending:
                // 구매 승인 대기중 (미처리 상태)
                print("Purchase pending...")
            @unknown default:
                break
            }
        } catch {
            print("⚠️ Purchase failed: \(error)")
        }
    }
    
    /// 현재 구독 활성화 여부 갱신 (예: 앱 런치 시 호출하여 기존 구독 확인)
    func updateSubscriptionStatus() async {
        // StoreKit 2의 최신 구독 현황 확인
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == "com.yourcompany.saveloope.premium" {
                // 활성화된 구독 상품이 있음
                await transaction.finish()  // (필요 시) 트랜잭션 마무리
                DispatchQueue.main.async {
                    self.isSubscribed = true
                }
            }
        }
    }
}
