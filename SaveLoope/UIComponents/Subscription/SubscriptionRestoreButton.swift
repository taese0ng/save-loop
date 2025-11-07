import SwiftUI

struct SubscriptionRestoreButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("구매 복원")
                .font(.subheadline)
                .foregroundColor(.blue)
        }
        .padding(.top, 8)
    }
}

#Preview {
    SubscriptionRestoreButton(action: {})
}

