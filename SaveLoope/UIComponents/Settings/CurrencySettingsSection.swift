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
                        Text("settings.currency_settings".localized) // 통화 설정
                            .foregroundColor(.primary)

                        Text(currentCurrencyName.isEmpty ? "common.loading".localized : currentCurrencyName) // 로딩 중...
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
            Text("settings.currency.section_header".localized) // 일반
        }
    }
}

