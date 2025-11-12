import SwiftUI
import StoreKit

struct SubscriptionStatusView: View {
    let subscriptionStatus: SubscriptionStatus
    let subscriptionInfo: SubscriptionInfo?
    let dateFormatter: DateFormatter
    let onManageTapped: () -> Void

    private var subscribedProduct: Product? {
        if case .subscribed(let product) = subscriptionStatus {
            return product
        }
        return nil
    }

    private var shouldShowManageButton: Bool {
        guard let product = subscribedProduct else { return false }
        return product.subscription != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            if let product = subscribedProduct {
                productInfo(for: product)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    private var header: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("subscription.current".localized) // 현재 구독 중
                .font(.headline)
            Spacer()

            if shouldShowManageButton {
                Button(action: onManageTapped) {
                    Text("subscription.manage_button".localized) // 구독 관리
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }

    private var productType: SubscriptionProduct? {
        guard let product = subscribedProduct else { return nil }
        return SubscriptionProduct.allCases.first { $0.rawValue == product.id }
    }
    
    private func localizedProductName(for product: Product) -> String {
        if let productType = SubscriptionProduct.allCases.first(where: { $0.rawValue == product.id }) {
            return productType.displayName
        }
        return product.displayName
    }

    @ViewBuilder
    private func productInfo(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localizedProductName(for: product)) // 다국어 지원된 이름 사용
                        .font(.body)
                        .fontWeight(.semibold)

                    if product.subscription != nil {
                        Text("subscription.subscribed_active".localized) // 구독 활성화됨
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("subscription.lifetime_active".localized) // 평생 이용권 활성화됨
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            if let info = subscriptionInfo {
                subscriptionDetail(info)
            }
        }
    }

    @ViewBuilder
    private func subscriptionDetail(_ info: SubscriptionInfo) -> some View {
        Divider()

        if let pendingProduct = info.pendingProduct {
            pendingChangeView(pendingProduct, renewalDate: info.renewalDate)
        } else if info.willRenew, let renewalDate = info.renewalDate {
            willRenewView(renewalDate)
        } else if !info.willRenew {
            willNotRenewView(info.renewalDate)
        }
    }

    private func pendingChangeView(_ pendingProduct: Product, renewalDate: Date?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("subscription.change_pending".localized) // 구독 변경 예정
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                Text(String(format: "subscription.change_to".localized, localizedProductName(for: pendingProduct))) // %@으로 변경
                    .font(.caption2)
                    .foregroundColor(.secondary)
                if let renewalDate {
                    Text(dateFormatter.string(from: renewalDate))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func willRenewView(_ renewalDate: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "arrow.clockwise.circle")
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text("subscription.next_billing".localized) // 다음 결제일
                    .font(.caption)
                    .fontWeight(.medium)
                Text(dateFormatter.string(from: renewalDate))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func willNotRenewView(_ renewalDate: Date?) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("subscription.auto_renew_off".localized) // 자동 갱신 해제됨
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                if let renewalDate {
                    Text(String(format: "subscription.available_until".localized, dateFormatter.string(from: renewalDate))) // %@까지 이용 가능
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

