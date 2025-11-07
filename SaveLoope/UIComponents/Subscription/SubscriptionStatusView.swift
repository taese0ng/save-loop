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
            Text("현재 구독 중")
                .font(.headline)
            Spacer()

            if shouldShowManageButton {
                Button(action: onManageTapped) {
                    Text("구독 관리")
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

    @ViewBuilder
    private func productInfo(for product: Product) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.displayName)
                        .font(.body)
                        .fontWeight(.semibold)

                    if product.subscription != nil {
                        Text("구독 활성화됨")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("평생 이용권 활성화됨")
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
                Text("구독 변경 예정")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                Text("\(pendingProduct.displayName)으로 변경")
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
                Text("다음 결제일")
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
                Text("자동 갱신 해제됨")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                if let renewalDate {
                    Text("\(dateFormatter.string(from: renewalDate))까지 이용 가능")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

