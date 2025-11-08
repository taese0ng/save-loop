import SwiftUI

struct BalanceTabs: View {
    var onAddBalance: () -> Void
    var onAddExpense: () -> Void

    func handleAddBalance() {
        onAddBalance()
    }

    func handleExpendBalance() {
        onAddExpense()
    }

    var body: some View {
            HStack(spacing: 0) { // 간격 없이 버튼이 연결되도록 설정
                Button(action: handleAddBalance) {
                    HStack {
                        Image(systemName: "plus.circle") // 아이콘
                        Text("잔액추가")
                    }
                    .frame(maxWidth: .infinity) // 너비를 균등하게 맞춤
                    .padding()
                    .frame(height: 50)
                    .background(Color(UIColor.systemGray6)) // 배경색 적용
                    .foregroundColor(.black) // 텍스트 색상
                    .font(.system(size: 16, weight: .medium)) // 폰트 크기 조정
                }
                
                Divider()
                .frame(height: 50)
                
                Button(action: handleExpendBalance) {
                    HStack {
                        Image(systemName: "minus.circle") // 아이콘
                        Text("지출")
                    }
                    .frame(maxWidth: .infinity) // 너비를 균등하게 맞춤
                    .padding()
                    .frame(height: 50)
                    .background(Color(UIColor.systemGray6)) // 배경색 적용
                    .foregroundColor(.black) // 텍스트 색상
                    .font(.system(size: 16, weight: .medium)) // 폰트 크기 조정
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 50) // HStack이 화면 전체를 차지하도록 설정
        }
}

#Preview {
    BalanceTabs(onAddBalance: {}, onAddExpense: {})
}

