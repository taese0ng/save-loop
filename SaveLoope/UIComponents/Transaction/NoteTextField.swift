import SwiftUI

struct NoteTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 16))
                .foregroundColor(Color("PrimaryText"))

            TextField(placeholder, text: $text)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
    }
}
