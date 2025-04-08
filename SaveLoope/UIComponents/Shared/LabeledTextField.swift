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
                    .foregroundColor(.black)
                
                if required {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                }
            }

            
            TextField(placeholder, text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical, 4)
        }
    }
}

#Preview {
    @Previewable @State var sampleText = "생활비"
    LabeledTextField(label: "봉투 이름", text: $sampleText)
}
