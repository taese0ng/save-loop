import SwiftUI
import StoreKit

struct SubscriptionProductCard: View {
    let product: Product
    let isSubscribed: Bool
    let isPending: Bool
    let onPurchase: () -> Void

    private var productType: SubscriptionProduct? {
        SubscriptionProduct.allCases.first { $0.rawValue == product.id }
    }

    private var isPopular: Bool {
        product.id == SubscriptionProduct.yearly.rawValue
    }

    private var isRecommended: Bool {
        product.id == SubscriptionProduct.lifetime.rawValue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            featuredBadge

            HStack(spacing: 16) {
                if let productType {
                    Image(systemName: productType.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.headline)

                    if let productType {
                        Text(productType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Divider()

            HStack {
                priceInfo

                Spacer()

                actionButton
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(borderGradient, lineWidth: 2)
        )
    }

    @ViewBuilder
    private var featuredBadge: some View {
        if isPopular || isRecommended {
            HStack {
                Spacer()
                Text(isRecommended ? "추천" : "인기")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(badgeGradient)
                    .cornerRadius(12)
            }
        }
    }

    private var badgeGradient: LinearGradient {
        if isRecommended {
            return LinearGradient(
                colors: [.blue, .purple],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        return LinearGradient(
            colors: [.orange, .orange],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var priceInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(product.displayPrice)
                .font(.title2)
                .fontWeight(.bold)

            if let subscription = product.subscription {
                Text("/ \(subscription.subscriptionPeriod.unit.localizedDescription)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("1회 결제")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isSubscribed {
            statusLabel(systemName: "checkmark.circle.fill", text: "구독 중", color: .green)
        } else if isPending {
            statusLabel(systemName: "clock.fill", text: "구독 예정", color: .orange)
        } else {
            Button(action: onPurchase) {
                Text("구독하기")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }

    private func statusLabel(systemName: String, text: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: systemName)
                .foregroundColor(color)
            Text(text)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .foregroundColor(color)
        .cornerRadius(10)
    }

    private var borderGradient: LinearGradient {
        if isRecommended {
            return LinearGradient(
                colors: [.blue, .purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        if isPopular {
            return LinearGradient(
                colors: [.orange, .orange],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        return LinearGradient(
            colors: [.clear, .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Product.SubscriptionPeriod.Unit {
    var localizedDescription: String {
        switch self {
        case .day:
            return "일"
        case .week:
            return "주"
        case .month:
            return "월"
        case .year:
            return "년"
        @unknown default:
            return ""
        }
    }
}

