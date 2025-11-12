import SwiftUI

struct EmptyStateView: View {
    var onAddEnvelope: () -> Void

    var body: some View {
        VStack(spacing: 45) {
            Text("home.empty_state.description") // 봉투를 추가해서\n돈을 관리해봐요!
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            AddEnvelopeButton(action: onAddEnvelope)
        }
    }
}

#Preview {
    EmptyStateView { }
}
