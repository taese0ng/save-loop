import SwiftUI

struct SubscriptionTermsView: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("subscription.terms.cancel_anytime".localized) // • 구독은 언제든지 취소할 수 있습니다
            Text("subscription.terms.no_refund".localized) // • 구독 취소 시 현재 기간 종료 후 자동 갱신되지 않습니다
            Text("subscription.terms.auto_renew".localized) // • 구독 갱신 24시간 전까지 자동으로 갱신됩니다
            Text("subscription.terms.manage".localized) // • '구독 관리' 버튼으로 취소 및 변경이 가능합니다
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.top, 16)
    }
}

#Preview {
    SubscriptionTermsView()
}

