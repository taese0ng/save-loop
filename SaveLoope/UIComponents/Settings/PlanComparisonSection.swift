import SwiftUI

struct PlanComparisonSection: View {
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @State private var showingPlanComparison = false

    var body: some View {
        Button(action: {
            showingPlanComparison = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "chart.bar.doc.horizontal")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("settings.plan_comparison.title".localized) // 플랜 비교
                        .foregroundColor(.primary)

                    Text("settings.plan_comparison.subtitle".localized) // 무료 vs 프리미엄 기능 비교
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingPlanComparison) {
            PlanComparisonSheet(subscriptionManager: subscriptionManager)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
    }
}
