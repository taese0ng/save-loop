import SwiftUI

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 100) // 🔹 타원형 배경 추가
                           .fill(Color.gray.opacity(0.2))
                    }
                    Image(systemName: icon)
                       .resizable()
                       .scaledToFit()
                       .frame(width: 24, height: 24) // 🔹 아이콘 크기 24px
                       .foregroundColor(isSelected ? .black : .gray)
                }
                .frame(width: 24 + 20 + 20, height: 24 + 8 + 8) // ✅ 아이콘보다 정확히 20px, 4px 크게 설정
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .black : .gray)
                    .fontWeight(isSelected ? .bold : .regular)
            }
        }
    }
}

#Preview {
    TabButton(icon: "house", title: "Home", isSelected: true) { }
}
