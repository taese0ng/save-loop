import SwiftUI

struct CurrencySettingsSection: View {
    let currentCurrencyName: String
    var onTap: () -> Void

    var body: some View {
        Section {
            Button(action: {
                onTap()
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("통화 설정")
                            .foregroundColor(.primary)

                        Text(currentCurrencyName.isEmpty ? "로딩 중..." : currentCurrencyName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("일반")
        }
    }
}

