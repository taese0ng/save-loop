import SwiftUI

struct SubscriptionHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("프리미엄으로 업그레이드")
                .font(.title2)
                .fontWeight(.bold)

            Text("무제한 봉투 생성과 고급 기능을 이용하세요")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
}

#Preview {
    SubscriptionHeaderView()
}

