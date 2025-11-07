import SwiftUI
import StoreKit

struct SubscriptionProductsSection: View {
    let products: [Product]
    let isLoading: Bool
    let errorMessage: String?
    let isSubscribed: (String) -> Bool
    let pendingProductId: String?
    let onPurchase: (Product) -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if products.isEmpty && !isLoading {
                emptyState
            } else {
                ForEach(products, id: \.id) { product in
                    SubscriptionProductCard(
                        product: product,
                        isSubscribed: isSubscribed(product.id),
                        isPending: pendingProductId == product.id,
                        onPurchase: { onPurchase(product) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            Text("제품을 불러올 수 없습니다")
                .font(.headline)

            Text(errorMessage ?? "네트워크 연결을 확인해주세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("다시 시도", action: onRetry)
                .buttonStyle(.bordered)
                .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
}

