import SwiftUI

struct PlanComparisonSheet: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    var showsCloseButton: Bool = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    freePlanSection
                    Divider()
                    premiumPlanSection
                }
                .padding()
            }
            .navigationTitle("플랜 비교")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if showsCloseButton {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }

    private var freePlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            planHeader(
                title: "무료 플랜",
                isCurrent: !subscriptionManager.isSubscribed,
                badgeStyle: .solid(.green)
            )

            VStack(alignment: .leading, spacing: 12) {
                PlanFeatureRow(icon: "envelope.fill", text: "봉투 3개까지", isIncluded: true, warningStyle: .standard)
                PlanFeatureRow(icon: "list.bullet", text: "봉투당 거래 30개까지", isIncluded: true, warningStyle: .standard)
                PlanFeatureRow(icon: "calendar", text: "최근 3개월 데이터 접근", isIncluded: true, warningStyle: .standard)
                PlanFeatureRow(icon: "icloud.fill", text: "iCloud 동기화", isIncluded: false)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var premiumPlanSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            planHeader(
                title: "프리미엄 플랜",
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
                PlanFeatureRow(icon: "envelope.fill", text: "무제한 봉투", isIncluded: true, isPremium: true)
                PlanFeatureRow(icon: "list.bullet", text: "무제한 거래 기록", isIncluded: true, isPremium: true)
                PlanFeatureRow(icon: "calendar", text: "무제한 데이터 접근", isIncluded: true, isPremium: true)
                PlanFeatureRow(icon: "icloud.fill", text: "iCloud 동기화", isIncluded: true, isPremium: true)
                PlanFeatureRow(icon: "sparkles", text: "앞으로 추가되는 기능들", isIncluded: true, isPremium: true)
            }
        }
        .padding()
        .background(Color(.systemGray6))
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
                Text("현재 플랜")
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

