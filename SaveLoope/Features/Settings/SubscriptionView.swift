import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "알림"
    @State private var showingManageSubscriptions = false

    // 한국식 날짜 포맷터
    private let koreanDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일"
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        SubscriptionHeaderView()

                        if case .subscribed = subscriptionManager.subscriptionStatus {
                            SubscriptionStatusView(
                                subscriptionStatus: subscriptionManager.subscriptionStatus,
                                subscriptionInfo: subscriptionManager.subscriptionInfo,
                                dateFormatter: koreanDateFormatter,
                                onManageTapped: { showingManageSubscriptions = true }
                            )
                        }

                        SubscriptionProductsSection(
                            products: filteredProducts,
                            isLoading: subscriptionManager.isLoading,
                            errorMessage: subscriptionManager.errorMessage,
                            isSubscribed: { subscriptionManager.isSubscribed(to: $0) },
                            pendingProductId: subscriptionManager.subscriptionInfo?.pendingProduct?.id,
                            onPurchase: { product in
                                Task {
                                    do {
                                        let success = try await subscriptionManager.purchase(product)
                                        if success {
                                            alertTitle = "구매 완료"
                                            alertMessage = "\(product.displayName) 구매가 완료되었습니다!"
                                            showingAlert = true
                                        }
                                    } catch {
                                        alertTitle = "구매 실패"
                                        alertMessage = subscriptionManager.errorMessage ?? "구매 중 오류가 발생했습니다."
                                        showingAlert = true
                                    }
                                }
                            },
                            onRetry: {
                                Task {
                                    await subscriptionManager.loadProducts()
                                }
                            }
                        )

                        SubscriptionRestoreButton {
                            Task {
                                await subscriptionManager.restorePurchases()

                                if subscriptionManager.isSubscribed {
                                    alertTitle = "복원 완료"
                                    alertMessage = "구매 내역을 복원했습니다."
                                } else {
                                    alertTitle = "복원 결과"
                                    alertMessage = "복원할 구매 내역이 없습니다."
                                }
                                showingAlert = true
                            }
                        }

                        SubscriptionTermsView()
                    }
                    .padding()
                }

                // 로딩 인디케이터
                if subscriptionManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("프리미엄 멤버십")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                }
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("확인", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .task {
                // 뷰가 나타날 때 제품 다시 로드
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                // 구독 상태 업데이트 (구독 취소 감지)
                await subscriptionManager.updateSubscriptionStatus()
            }
            .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
            .onChange(of: showingManageSubscriptions) { oldValue, newValue in
                // 구독 관리 화면이 닫힐 때 상태 업데이트
                if oldValue && !newValue {
                    Task {
                        await subscriptionManager.updateSubscriptionStatus()
                    }
                }
            }
        }
    }

    // 평생 이용권이 있으면 월간/연간 구독권 필터링
    private var filteredProducts: [Product] {
        let hasLifetime = subscriptionManager.isSubscribed(to: SubscriptionProduct.lifetime.rawValue)

        if hasLifetime {
            // 평생 이용권만 표시
            return subscriptionManager.products.filter { product in
                product.id == SubscriptionProduct.lifetime.rawValue
            }
        } else {
            // 모든 제품 표시
            return subscriptionManager.products
        }
    }

}

#Preview {
    SubscriptionView()
}
