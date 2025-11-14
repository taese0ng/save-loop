import SwiftUI
import StoreKit

struct SubscriptionView: View {
    var showsCloseButton: Bool = true

    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "common.alert".localized // 알림
    @State private var showingManageSubscriptions = false

    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    // 현재 언어에 맞는 날짜 포맷터
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = localizationManager.getCurrentLocale()
        // 날짜 형식은 로케일에 따라 자동으로 설정되도록 함
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }

    var body: some View {
        StandardSheetContainer(
            title: "subscription.title".localized, // 프리미엄 멤버십
            trailingAccessory: {
                if showsCloseButton {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("SecondaryText"))
                            .padding(8)
                    }
                }
            }
        ) {
            ZStack {
                ScrollView {
                    VStack(spacing: 24) {
                        SubscriptionHeaderView()

                        if case .subscribed = subscriptionManager.subscriptionStatus {
                            SubscriptionStatusView(
                                subscriptionStatus: subscriptionManager.subscriptionStatus,
                                subscriptionInfo: subscriptionManager.subscriptionInfo,
                                dateFormatter: dateFormatter,
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
                                            let localizedName = SubscriptionProduct.allCases.first(where: { $0.rawValue == product.id })?.displayName ?? product.displayName
                                            alertTitle = "subscription.purchase_complete_title".localized // 구매 완료
                                            alertMessage = String(format: "subscription.purchase_complete_message".localized, localizedName) // "%@ 구매가 완료되었습니다!"
                                            showingAlert = true
                                        }
                                    } catch {
                                        alertTitle = "subscription.purchase_failed_title".localized // 구매 실패
                                        alertMessage = subscriptionManager.errorMessage ?? "subscription.purchase_failed_message".localized // 구매 중 오류가 발생했습니다.
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
                                    alertTitle = "subscription.restore_complete_title".localized // 복원 완료
                                    alertMessage = "subscription.restore_complete_message".localized // 구매 내역을 복원했습니다.
                                } else {
                                    alertTitle = "subscription.restore_none_title".localized // 복원 결과
                                    alertMessage = "subscription.restore_none_message".localized // 복원할 구매 내역이 없습니다.
                                }
                                showingAlert = true
                            }
                        }
                        
                        // 구독 해지 안내
                        UnsubscribeInfoSection()

                        SubscriptionTermsView()
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)

                if subscriptionManager.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
            }
        }
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("common.ok".localized, role: .cancel) { } // 확인
        } message: {
            Text(alertMessage)
        }
        .task {
            await subscriptionManager.loadProducts()
            await subscriptionManager.updateSubscriptionStatus()
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .onChange(of: showingManageSubscriptions) { oldValue, newValue in
            if oldValue && !newValue {
                Task {
                    await subscriptionManager.updateSubscriptionStatus()
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

// MARK: - 구독 해지 안내 섹션
struct UnsubscribeInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
                Text("premium.unsubscribe.title".localized) // 구독 해지 시 변경 사항
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color("PrimaryText"))
            }
            
            Text("premium.unsubscribe.message".localized)
                .font(.system(size: 13))
                .foregroundColor(Color("SecondaryText"))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    SubscriptionView()
}
