import SwiftUI

struct MembershipSection: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let onTap: () -> Void

    var body: some View {
        Section {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: subscriptionManager.isSubscribed ? "star.fill" : "star")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("프리미엄 멤버십")
                            .foregroundColor(.primary)

                        if subscriptionManager.isSubscribed,
                           case .subscribed(let product) = subscriptionManager.subscriptionStatus {
                            Text("\(product.displayName) 구독 중")
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        } else {
                            Text("무제한 기능 사용하기")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("멤버십")
        }
    }
}
