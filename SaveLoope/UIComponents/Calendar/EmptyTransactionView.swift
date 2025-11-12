import SwiftUI

struct EmptyTransactionView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("calendar.empty".localized) // 거래내역이 없습니다
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
