import SwiftUI

struct SubmitButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        HStack {
            Spacer()
            Button(action: action) {
                Text(title)
                    .font(.system(size: 20, weight: .light))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 32)
            .background(Color.blue)
            .cornerRadius(8)
            Spacer()
        }
    }
}
