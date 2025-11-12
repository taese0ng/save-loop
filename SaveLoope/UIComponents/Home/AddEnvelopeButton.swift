import SwiftUI

struct AddEnvelopeButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("home.add_envelope".localized) // 봉투 추가
                .font(.system(size:20, weight: .light))
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 32)
        .background(Color.blue)
        .cornerRadius(8) 
    }
}

#Preview {
    AddEnvelopeButton { }
}
