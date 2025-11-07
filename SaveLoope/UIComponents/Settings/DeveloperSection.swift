import SwiftUI

struct DeveloperSection: View {
    @Binding var showingResetAlert: Bool
    @Binding var isDeveloperModeEnabled: Bool
    @Binding var showingDeveloperModeAlert: Bool

    var body: some View {
        Section {
            Button(action: {
                showingResetAlert = true
            }) {
                HStack {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    Text("데이터 초기화")
                        .foregroundColor(.red)
                }
            }

            // 개발자 모드 비활성화 버튼
            Button(action: {
                isDeveloperModeEnabled = false
                showingDeveloperModeAlert = true
            }) {
                HStack {
                    Image(systemName: "hammer.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)
                    Text("개발자 모드 비활성화")
                        .foregroundColor(.orange)
                }
            }
        } header: {
            Text("개발자 도구")
        } footer: {
            Text("⚠️ 개발자 전용 기능입니다. 데이터 초기화 시 모든 봉투(Envelope)와 거래 기록(Transaction Record)이 삭제됩니다.")
                .foregroundColor(.secondary)
        }
    }
}
