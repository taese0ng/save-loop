import SwiftUI

struct ActionButtons: View {
    let deleteTitle: String
    let confirmTitle: String
    let onDelete: () -> Void
    let onConfirm: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onDelete) {
                Text(deleteTitle)
                    .font(.system(size: 20, weight: .light))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color("DeleteButton"))
            .cornerRadius(8)

            Button(action: onConfirm) {
                Text(confirmTitle)
                    .font(.system(size: 20, weight: .light))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color("EditButton"))
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.bottom, 24)
    }
}
