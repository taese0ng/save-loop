import SwiftUI

struct SettingsHeader: View {
    @Binding var isDeveloperModeEnabled: Bool
    let onDeveloperModeTap: () -> Void

    var body: some View {
        HStack {
            Text("설정")
                .font(.largeTitle)
                .fontWeight(.bold)

            if isDeveloperModeEnabled {
                Image(systemName: "hammer.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
        .background(Color.white)
        .contentShape(Rectangle())
        .onTapGesture {
            // 개발자 모드가 비활성화 상태일 때만 탭 카운트
            if !isDeveloperModeEnabled {
                onDeveloperModeTap()
            }
        }
    }
}
