import SwiftUI

struct BackButton: View {
    let onDismiss: () -> Void
    
    var body: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle()
                    .fill(Color.clear)
                    .frame(width: 38, height: 38)

                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color("PrimaryText"))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .fixedSize()
    }
}
