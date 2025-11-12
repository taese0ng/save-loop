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
                    HStack {
                        Text(productType?.displayName ?? product.displayName) // 다국어 지원된 이름 사용
                            .font(.headline)
                        
                        Spacer()
                        
                        if isPopular || isRecommended {
                            Text(isRecommended ? "subscription.product.recommended".localized : "subscription.product.popular".localized) // 추천 / 인기
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(badgeGradient)
                                .cornerRadius(12)
                        }
                    }

                    if let productType {
                        Text(productType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            HStack {
                priceInfo

                Spacer()

                actionButton
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .shadow(color: Color("Separator"), radius: 8, x: 0, y: 2)
        .overlay(
            Group {
                if isRecommended || isPopular {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderGradient, lineWidth: 2)
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color("Separator"), lineWidth: 1)
                }
            }
        )
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
                Text("subscription.product.one_time".localized) // 1회 결제
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        if isSubscribed {
            statusLabel(systemName: "checkmark.circle.fill", text: "subscription.product.subscribed".localized, color: .green) // 구독 중
        } else if isPending {
            statusLabel(systemName: "clock.fill", text: "subscription.product.pending".localized, color: .orange) // 구독 예정
        } else {
            Button(action: onPurchase) {
                Text("subscription.product.subscribe".localized) // 구독하기
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
            return "subscription.product.period.day".localized // 일
        case .week:
            return "subscription.product.period.week".localized // 주
        case .month:
            return "subscription.product.period.month".localized // 월
        case .year:
            return "subscription.product.period.year".localized // 년
        @unknown default:
            return ""
        }
    }
}

