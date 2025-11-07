import Foundation
import StoreKit

/// 구독 관리 클래스
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProducts: [Product] = []
    @Published private(set) var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published private(set) var subscriptionInfo: SubscriptionInfo?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    /// 제품 정보 로드
    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let productIdentifiers = SubscriptionProduct.allCases.map { $0.rawValue }
            print("🔍 제품 ID 로드 시도: \(productIdentifiers)")

            let loadedProducts = try await Product.products(for: productIdentifiers)
            print("📦 StoreKit에서 반환된 제품 개수: \(loadedProducts.count)")

            if !loadedProducts.isEmpty {
                for product in loadedProducts {
                    print("  - \(product.id): \(product.displayName)")
                }
            }

            // 월간, 연간, 평생 순서로 정렬
            self.products = loadedProducts.sorted { lhs, rhs in
                let lhsIndex = SubscriptionProduct.allCases.firstIndex { $0.rawValue == lhs.id } ?? 999
                let rhsIndex = SubscriptionProduct.allCases.firstIndex { $0.rawValue == rhs.id } ?? 999
                return lhsIndex < rhsIndex
            }

            if products.isEmpty {
                errorMessage = "사용 가능한 제품이 없습니다. StoreKit Configuration을 확인해주세요."
                print("⚠️ 제품이 로드되지 않았습니다. StoreKit Configuration을 확인하세요.")
                print("💡 Xcode에서: Product > Scheme > Edit Scheme > Options > StoreKit Configuration 파일을 직접 선택하세요")
            } else {
                errorMessage = nil
                print("✅ \(products.count)개의 구독 제품 로드 완료")
            }
        } catch {
            errorMessage = "제품 정보를 불러올 수 없습니다. 네트워크 연결을 확인해주세요."
            print("❌ 제품 로드 실패: \(error)")
            print("❌ 에러 상세: \(error.localizedDescription)")
        }

        isLoading = false
    }

    /// 제품 구매
    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // 구매 검증
                let transaction = try Self.checkVerified(verification)

                // 트랜잭션 종료
                await transaction.finish()

                // 구매 완료 즉시 UI 업데이트
                await updateSubscriptionStatusImmediately(with: product)

                print("✅ 구매 성공: \(product.displayName)")
                isLoading = false
                return true

            case .userCancelled:
                print("ℹ️ 사용자가 구매를 취소했습니다.")
                isLoading = false
                return false

            case .pending:
                print("⏳ 구매 승인 대기 중")
                isLoading = false
                return false

            @unknown default:
                print("⚠️ 알 수 없는 구매 결과")
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "구매 중 오류가 발생했습니다."
            print("❌ 구매 실패: \(error)")
            isLoading = false
            throw error
        }
    }

    /// 구매 복원
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            print("✅ 구매 복원 완료")
        } catch {
            errorMessage = "구매 복원 중 오류가 발생했습니다."
            print("❌ 구매 복원 실패: \(error)")
        }

        isLoading = false
    }

    /// 구매 완료 후 즉시 구독 상태 업데이트
    private func updateSubscriptionStatusImmediately(with newProduct: Product) async {
        // 기존 구매 제품 리스트를 비동기로 가져오기
        var activeSubscriptions: [Product] = []

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscriptions.append(product)
                }
            } catch {
                print("❌ 트랜잭션 검증 실패: \(error)")
            }
        }

        // 새로 구매한 제품이 리스트에 없으면 추가
        if !activeSubscriptions.contains(where: { $0.id == newProduct.id }) {
            activeSubscriptions.append(newProduct)
        }

        purchasedProducts = activeSubscriptions

        // 구독 상태 결정 (우선순위: 평생 > 연간 > 월간)
        if let subscribedProduct = selectBestSubscription(from: activeSubscriptions) {
            subscriptionStatus = .subscribed(subscribedProduct)
            print("✅ 활성 구독: \(subscribedProduct.displayName)")

            // 구독 갱신 정보 가져오기
            await updateSubscriptionInfo(for: subscribedProduct)
        } else {
            subscriptionStatus = .notSubscribed
            subscriptionInfo = nil
            print("ℹ️ 활성 구독 없음")
        }
    }

    /// 구독 상태 업데이트
    func updateSubscriptionStatus() async {
        var activeSubscriptions: [Product] = []

        // 현재 활성화된 구독 확인
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try Self.checkVerified(result)

                // 제품이 로드되지 않았다면 다시 로드
                if products.isEmpty {
                    await loadProducts()
                }

                // 제품 정보 찾기
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    activeSubscriptions.append(product)
                }
            } catch {
                print("❌ 트랜잭션 검증 실패: \(error)")
            }
        }

        purchasedProducts = activeSubscriptions

        // 구독 상태 결정 (우선순위: 평생 > 연간 > 월간)
        if let subscribedProduct = selectBestSubscription(from: activeSubscriptions) {
            subscriptionStatus = .subscribed(subscribedProduct)
            print("✅ 활성 구독: \(subscribedProduct.displayName)")

            // 구독 갱신 정보 가져오기
            await updateSubscriptionInfo(for: subscribedProduct)
        } else {
            subscriptionStatus = .notSubscribed
            subscriptionInfo = nil
            print("ℹ️ 활성 구독 없음")

            // 구독이 해지된 경우 iCloud 동기화 자동 비활성화
            await CloudSyncManager.shared.checkSubscriptionAndDisableSyncIfNeeded()
        }
    }

    /// 구독 갱신 정보 업데이트
    private func updateSubscriptionInfo(for product: Product) async {
        guard let subscription = product.subscription else {
            subscriptionInfo = nil
            return
        }

        do {
            // 구독 상태 확인
            let statuses = try await subscription.status

            guard let status = statuses.first else {
                subscriptionInfo = nil
                return
            }

            let transaction = try Self.checkVerified(status.transaction)
            let renewalInfo = try Self.checkVerified(status.renewalInfo)

            // 갱신 예정 제품 확인
            var pendingProduct: Product? = nil
            if renewalInfo.willAutoRenew {
                // 다음 갱신 시 변경될 제품이 있는지 확인
                if let autoRenewPreference = renewalInfo.autoRenewPreference,
                   autoRenewPreference != transaction.productID {
                    pendingProduct = products.first { $0.id == autoRenewPreference }
                }
            }

            // 만료일은 transaction의 expirationDate 사용
            let expirationDate = transaction.expirationDate

            subscriptionInfo = SubscriptionInfo(
                currentProduct: product,
                willRenew: renewalInfo.willAutoRenew,
                renewalDate: expirationDate,
                pendingProduct: pendingProduct
            )

            if let pending = pendingProduct {
                print("📅 구독 변경 예정: \(product.displayName) → \(pending.displayName)")
            } else if renewalInfo.willAutoRenew {
                print("🔄 자동 갱신 활성화")
            } else {
                print("⚠️ 자동 갱신 비활성화")
            }
        } catch {
            print("❌ 구독 정보 업데이트 실패: \(error)")
            subscriptionInfo = nil
        }
    }

    /// 여러 구독 중 가장 우선순위가 높은 구독 선택
    private func selectBestSubscription(from products: [Product]) -> Product? {
        // 우선순위: 평생 > 연간 > 월간
        if let lifetime = products.first(where: { $0.id == SubscriptionProduct.lifetime.rawValue }) {
            return lifetime
        }
        if let yearly = products.first(where: { $0.id == SubscriptionProduct.yearly.rawValue }) {
            return yearly
        }
        if let monthly = products.first(where: { $0.id == SubscriptionProduct.monthly.rawValue }) {
            return monthly
        }
        return products.first
    }

    /// 트랜잭션 리스너
    private func listenForTransactions() -> Task<Void, Error> {
        return Task {
            // 새로운 트랜잭션 감지
            for await result in Transaction.updates {
                do {
                    let transaction = try Self.checkVerified(result)

                    // 구독 상태 업데이트
                    await updateSubscriptionStatus()

                    // 트랜잭션 종료
                    await transaction.finish()
                } catch {
                    print("❌ 트랜잭션 업데이트 처리 실패: \(error)")
                }
            }
        }
    }

    /// 트랜잭션 검증
    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    /// 구독 여부 확인
    var isSubscribed: Bool {
        if case .subscribed = subscriptionStatus {
            return true
        }
        return false
    }

    /// 특정 제품 구독 여부 확인
    func isSubscribed(to productIdentifier: String) -> Bool {
        return purchasedProducts.contains { $0.id == productIdentifier }
    }
}

