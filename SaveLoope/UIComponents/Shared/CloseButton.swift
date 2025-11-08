import SwiftUI

struct CloseButton: View {
    let onDismiss: () -> Void

    var body: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
            }
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .fixedSize()
    }
}
