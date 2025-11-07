import SwiftUI

struct ActionButtons: View {
    let deleteTitle: String
    let confirmTitle: String
    let onDelete: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 20) {
                Button(action: onDelete) {
                    Text(deleteTitle)
                        .font(.system(size: 20, weight: .light))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .background(Color(red: 0.95, green: 0.3, blue: 0.3))
                .cornerRadius(8)

                Button(action: onConfirm) {
                    Text(confirmTitle)
                        .font(.system(size: 20, weight: .light))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 12)
                .background(Color(red: 0.3, green: 0.5, blue: 0.95))
                .cornerRadius(8)
            }
            .padding()
            .background(Color.white)
        }
    }
}
