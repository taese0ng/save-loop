import SwiftUI

struct BackButton: View {
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle()
                    .fill(Color("Separator"))
                    .frame(width: 40, height: 40)

                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
            }
            .contentShape(Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .fixedSize()
    }
}
