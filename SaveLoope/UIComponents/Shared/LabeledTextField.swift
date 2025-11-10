import SwiftUI

struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var required: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 3){
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color("PrimaryText"))

                if required {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }


            TextField(placeholder, text: $text)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    @Previewable @State var sampleText = "생활비"
    LabeledTextField(label: "봉투 이름", text: $sampleText)
}
