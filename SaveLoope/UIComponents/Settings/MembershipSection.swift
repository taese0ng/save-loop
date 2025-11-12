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
                        Text("settings.membership.premium".localized) // 프리미엄 멤버십
                            .foregroundColor(.primary)

                        if subscriptionManager.isSubscribed,
                           case .subscribed(let product) = subscriptionManager.subscriptionStatus {
                            let localizedName = SubscriptionProduct.allCases.first(where: { $0.rawValue == product.id })?.displayName ?? product.displayName
                            Text(String(format: "settings.membership.subscribed".localized, localizedName)) // %@ 구독 중
                                .font(.caption)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        } else {
                            Text("settings.membership.unlimited".localized) // 무제한 기능 사용하기
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
            Text("settings.membership.section_header".localized) // 멤버십
        }
    }
}
