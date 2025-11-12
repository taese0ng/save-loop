import SwiftUI

struct PlanComparisonSheet: View {
    @ObservedObject var subscriptionManager: SubscriptionManager

    var body: some View {
        StandardSheetContainer(title: "settings.plan_comparison.title".localized) { // 플랜 비교
            ScrollView {
                VStack(spacing: 24) {
                    freePlanSection
                    Divider()
                    premiumPlanSection
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var freePlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            planHeader(
                title: "plan.free.title".localized, // 무료 플랜
                isCurrent: !subscriptionManager.isSubscribed,
                badgeStyle: .solid(.green)
            )

            VStack(alignment: .leading, spacing: 12) {
                PlanFeatureRow(icon: "envelope.fill", text: "plan.feature.envelopes_3".localized, isIncluded: true, warningStyle: .standard) // 봉투 3개까지
                PlanFeatureRow(icon: "arrow.clockwise", text: "plan.feature.persistent_envelope".localized, isIncluded: false) // 지속형 봉투
                PlanFeatureRow(icon: "list.bullet", text: "plan.feature.transactions_30".localized, isIncluded: true, warningStyle: .standard) // 봉투당 거래 30개까지
                PlanFeatureRow(icon: "calendar", text: "plan.feature.months_3".localized, isIncluded: true, warningStyle: .standard) // 최근 3개월 데이터 접근
                PlanFeatureRow(icon: "icloud.fill", text: "plan.feature.cloud_sync".localized, isIncluded: false) // iCloud 동기화
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color("Separator"), lineWidth: 1)
        )
    }

    private var premiumPlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            planHeader(
                title: "plan.premium.title".localized, // 프리미엄 플랜
                isCurrent: subscriptionManager.isSubscribed,
                badgeStyle: .gradient(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            )

            VStack(alignment: .leading, spacing: 12) {
                PlanFeatureRow(icon: "envelope.fill", text: "plan.feature.envelopes_unlimited".localized, isIncluded: true, isPremium: true) // 무제한 봉투
                PlanFeatureRow(icon: "arrow.clockwise", text: "plan.feature.persistent_envelope".localized, isIncluded: true, isPremium: true) // 지속형 봉투
                PlanFeatureRow(icon: "list.bullet", text: "plan.feature.transactions_unlimited".localized, isIncluded: true, isPremium: true) // 무제한 거래 기록
                PlanFeatureRow(icon: "calendar", text: "plan.feature.months_unlimited".localized, isIncluded: true, isPremium: true) // 무제한 데이터 접근
                PlanFeatureRow(icon: "icloud.fill", text: "plan.feature.cloud_sync".localized, isIncluded: true, isPremium: true) // iCloud 동기화
                PlanFeatureRow(icon: "sparkles", text: "plan.feature.future_features".localized, isIncluded: true, isPremium: true) // 앞으로 추가되는 기능들
            }
        }
        .padding()
        .background(Color("CardBackground"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }

    private func planHeader(title: String, isCurrent: Bool, badgeStyle: PlanBadgeStyle?) -> some View {
        HStack {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)

            if isCurrent, let badgeStyle {
                Text("plan.current_badge".localized) // 현재 플랜
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(badgeBackground(for: badgeStyle))
                    .cornerRadius(12)
            }

            Spacer()
        }
    }
}

private enum PlanBadgeStyle {
    case solid(Color)
    case gradient(LinearGradient)
}

@ViewBuilder
private func badgeBackground(for style: PlanBadgeStyle) -> some View {
    switch style {
    case .solid(let color):
        color
    case .gradient(let gradient):
        gradient
    }
}

private struct PlanFeatureRow: View {
    let icon: String
    let text: String
    let isIncluded: Bool
    var isPremium: Bool = false
    var warningStyle: WarningStyle? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundColor(symbolColor)
                .font(.system(size: 14))

            Image(systemName: icon)
                .foregroundColor(isPremium ? .blue : .primary)
                .font(.system(size: 14))
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(isIncluded ? .primary : .secondary)
        }
    }

    private var symbolName: String {
        if isIncluded {
            return warningStyle != nil ? "exclamationmark.triangle.fill" : "checkmark.circle.fill"
        }
        return "xmark.circle.fill"
    }

    private var symbolColor: Color {
        if isIncluded, let warningStyle {
            return warningStyle.color
        }
        if !isIncluded {
            return .gray
        }
        return isPremium ? .blue : .green
    }
}

private enum WarningStyle {
    case standard

    var color: Color {
        switch self {
        case .standard:
            return .yellow
        }
    }
}

#Preview {
    PlanComparisonSheet(subscriptionManager: SubscriptionManager.shared)
}

